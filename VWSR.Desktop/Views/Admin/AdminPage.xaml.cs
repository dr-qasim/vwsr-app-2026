using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using Microsoft.Win32;

namespace VWSR.Desktop;

public partial class AdminPage : Page
{
    private readonly HttpClient _httpClient = new();
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };
    private int _page = 1;
    private int _pageSize = 20;
    private int _total;

    public ObservableCollection<VendingMachineRow> Machines { get; } = new();

    public AdminPage()
    {
        InitializeComponent();
        DataContext = this;

        _httpClient.BaseAddress = new Uri(Session.ApiBaseUrl ?? "http://localhost:5000/");

        Loaded += async (_, _) => await LoadMachines();
    }

    private async Task LoadMachines()
    {
        try
        {
            // Загружаем список ТА через API с пагинацией и фильтром.
            var search = SearchBox.Text?.Trim();
            var url = $"api/vending-machines?search={Uri.EscapeDataString(search ?? string.Empty)}&page={_page}&pageSize={_pageSize}";

            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            ApplyAuth(request);

            var response = await _httpClient.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                MessageBox.Show("Не удалось получить список ТА.");
                return;
            }

            var body = await response.Content.ReadAsStringAsync();
            var pageResult = JsonSerializer.Deserialize<PagedResult<VendingMachineListItem>>(body, _jsonOptions);
            if (pageResult == null)
            {
                return;
            }

            _total = pageResult.Total;
            _page = pageResult.Page;
            _pageSize = pageResult.PageSize;

            Machines.Clear();
            foreach (var item in pageResult.Items)
            {
                Machines.Add(new VendingMachineRow
                {
                    Id = item.Id,
                    Name = item.Name,
                    Model = item.Model,
                    Company = item.Company ?? string.Empty,
                    ModemId = item.ModemId,
                    Address = item.Address,
                    Place = item.Place,
                    WorkingSince = item.WorkingSince
                });
            }

            UpdatePagingInfo();
            ApplyGrouping();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
    }

    private void ApplyGrouping()
    {
        // Простейшая группировка по франчайзи.
        var view = CollectionViewSource.GetDefaultView(Machines);
        view.GroupDescriptions.Clear();

        if (GroupByCompany.IsChecked == true)
        {
            view.GroupDescriptions.Add(new PropertyGroupDescription(nameof(VendingMachineRow.Company)));
        }
    }

    private void UpdatePagingInfo()
    {
        var from = Machines.Count == 0 ? 0 : (_page - 1) * _pageSize + 1;
        var to = (_page - 1) * _pageSize + Machines.Count;

        PageInfo.Text = $"Стр. {_page}";
        TotalInfo.Text = $"Показано {from}-{to} из {_total}";
    }

    private void ApplyAuth(HttpRequestMessage request)
    {
        if (!string.IsNullOrWhiteSpace(Session.AccessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", Session.AccessToken);
        }
    }

    private void Refresh_Click(object sender, RoutedEventArgs e)
    {
        _page = 1;
        _ = LoadMachines();
    }

    private void PageSizeBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (PageSizeBox.SelectedItem is ComboBoxItem item && int.TryParse(item.Content?.ToString(), out var size))
        {
            _pageSize = size;
            _page = 1;
            _ = LoadMachines();
        }
    }

    private void Prev_Click(object sender, RoutedEventArgs e)
    {
        if (_page > 1)
        {
            _page--;
            _ = LoadMachines();
        }
    }

    private void Next_Click(object sender, RoutedEventArgs e)
    {
        var maxPage = (int)Math.Ceiling(_total / (double)_pageSize);
        if (_page < maxPage)
        {
            _page++;
            _ = LoadMachines();
        }
    }

    private void TableView_Click(object sender, RoutedEventArgs e)
    {
        MachinesGrid.Visibility = Visibility.Visible;
        TilesPanel.Visibility = Visibility.Collapsed;
    }

    private void TileView_Click(object sender, RoutedEventArgs e)
    {
        MachinesGrid.Visibility = Visibility.Collapsed;
        TilesPanel.Visibility = Visibility.Visible;
    }

    private void GroupByCompany_Checked(object sender, RoutedEventArgs e)
    {
        ApplyGrouping();
    }

    private async void Add_Click(object sender, RoutedEventArgs e)
    {
        var form = new VendingMachineFormWindow(null);
        if (form.ShowDialog() == true)
        {
            await LoadMachines();
        }
    }

    private async void Edit_Click(object sender, RoutedEventArgs e)
    {
        if (GetRowFromSender(sender) is not VendingMachineRow row)
        {
            return;
        }

        var detail = await LoadDetail(row.Id);
        if (detail == null)
        {
            MessageBox.Show("Не удалось открыть данные ТА.");
            return;
        }

        var form = new VendingMachineFormWindow(detail);
        if (form.ShowDialog() == true)
        {
            await LoadMachines();
        }
    }

    private async void Delete_Click(object sender, RoutedEventArgs e)
    {
        if (GetRowFromSender(sender) is not VendingMachineRow row)
        {
            return;
        }

        if (MessageBox.Show("Удалить ТА?", "Подтверждение", MessageBoxButton.YesNo) != MessageBoxResult.Yes)
        {
            return;
        }

        using var request = new HttpRequestMessage(HttpMethod.Delete, $"api/vending-machines/{row.Id}");
        ApplyAuth(request);
        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            MessageBox.Show("Не удалось удалить ТА.");
            return;
        }

        await LoadMachines();
    }

    private async void Unlink_Click(object sender, RoutedEventArgs e)
    {
        if (GetRowFromSender(sender) is not VendingMachineRow row)
        {
            return;
        }

        if (MessageBox.Show("Отвязать модем?", "Подтверждение", MessageBoxButton.YesNo) != MessageBoxResult.Yes)
        {
            return;
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, $"api/vending-machines/{row.Id}/unlink-modem");
        ApplyAuth(request);
        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            MessageBox.Show("Не удалось отвязать модем.");
            return;
        }

        await LoadMachines();
    }

    private VendingMachineRow? GetRowFromSender(object sender)
    {
        return (sender as FrameworkElement)?.DataContext as VendingMachineRow;
    }

    private async Task<VendingMachineDetail?> LoadDetail(int id)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, $"api/vending-machines/{id}");
        ApplyAuth(request);
        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        var body = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<VendingMachineDetail>(body, _jsonOptions);
    }

    private void ExportCsv_Click(object sender, RoutedEventArgs e)
    {
        var path = GetSavePath("CSV files|*.csv", "vending.csv");
        if (path == null)
        {
            return;
        }

        var sb = new StringBuilder();
        sb.AppendLine("Id;Name;Model;Company;Modem;Address;Place;WorkingSince");

        foreach (var item in Machines)
        {
            sb.AppendLine($"{item.Id};{item.Name};{item.Model};{item.Company};{item.ModemId};{item.Address};{item.Place};{item.WorkingSince:dd.MM.yyyy}");
        }

        System.IO.File.WriteAllText(path, sb.ToString(), Encoding.UTF8);
        MessageBox.Show("Экспорт CSV выполнен.");
    }

    private void ExportHtml_Click(object sender, RoutedEventArgs e)
    {
        var path = GetSavePath("HTML files|*.html", "vending.html");
        if (path == null)
        {
            return;
        }

        var sb = new StringBuilder();
        sb.AppendLine("<html><head><meta charset=\"utf-8\"></head><body>");
        sb.AppendLine("<table border=\"1\" cellspacing=\"0\" cellpadding=\"4\">");
        sb.AppendLine("<tr><th>ID</th><th>Название</th><th>Модель</th><th>Компания</th><th>Модем</th><th>Адрес</th><th>Место</th><th>В работе с</th></tr>");

        foreach (var item in Machines)
        {
            sb.AppendLine($"<tr><td>{item.Id}</td><td>{item.Name}</td><td>{item.Model}</td><td>{item.Company}</td><td>{item.ModemId}</td><td>{item.Address}</td><td>{item.Place}</td><td>{item.WorkingSince:dd.MM.yyyy}</td></tr>");
        }

        sb.AppendLine("</table></body></html>");
        System.IO.File.WriteAllText(path, sb.ToString(), Encoding.UTF8);
        MessageBox.Show("Экспорт HTML выполнен.");
    }

    private void ExportPdf_Click(object sender, RoutedEventArgs e)
    {
        var path = GetSavePath("PDF files|*.pdf", "vending.pdf");
        if (path == null)
        {
            return;
        }

        // Очень простой PDF с текстом (минимально, без библиотек).
        PdfExporter.WriteSimplePdf(path, Machines);
        MessageBox.Show("Экспорт PDF выполнен.");
    }

    private static string? GetSavePath(string filter, string fileName)
    {
        var dialog = new SaveFileDialog
        {
            Filter = filter,
            FileName = fileName
        };

        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }
}

public static class PdfExporter
{
    public static void WriteSimplePdf(string path, ObservableCollection<VendingMachineRow> rows)
    {
        // Пишем простой PDF с одной страницей и строками текста.
        using var stream = new System.IO.MemoryStream();
        using var writer = new System.IO.StreamWriter(stream, Encoding.ASCII, leaveOpen: true);

        var offsets = new int[6];

        writer.WriteLine("%PDF-1.4");
        offsets[1] = (int)stream.Position;
        writer.WriteLine("1 0 obj");
        writer.WriteLine("<< /Type /Catalog /Pages 2 0 R >>");
        writer.WriteLine("endobj");

        offsets[2] = (int)stream.Position;
        writer.WriteLine("2 0 obj");
        writer.WriteLine("<< /Type /Pages /Kids [3 0 R] /Count 1 >>");
        writer.WriteLine("endobj");

        offsets[3] = (int)stream.Position;
        writer.WriteLine("3 0 obj");
        writer.WriteLine("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>");
        writer.WriteLine("endobj");

        offsets[4] = (int)stream.Position;
        writer.WriteLine("4 0 obj");
        writer.WriteLine("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");
        writer.WriteLine("endobj");

        var content = BuildPdfContent(rows);
        offsets[5] = (int)stream.Position;
        writer.WriteLine("5 0 obj");
        writer.WriteLine($"<< /Length {content.Length} >>");
        writer.WriteLine("stream");
        writer.Write(content);
        writer.WriteLine("\nendstream");
        writer.WriteLine("endobj");

        var xrefPosition = (int)stream.Position;
        writer.WriteLine("xref");
        writer.WriteLine("0 6");
        writer.WriteLine("0000000000 65535 f ");
        for (var i = 1; i <= 5; i++)
        {
            writer.WriteLine($"{offsets[i]:D10} 00000 n ");
        }

        writer.WriteLine("trailer");
        writer.WriteLine("<< /Size 6 /Root 1 0 R >>");
        writer.WriteLine("startxref");
        writer.WriteLine(xrefPosition);
        writer.WriteLine("%%EOF");
        writer.Flush();

        System.IO.File.WriteAllBytes(path, stream.ToArray());
    }

    private static string BuildPdfContent(ObservableCollection<VendingMachineRow> rows)
    {
        var sb = new StringBuilder();
        sb.AppendLine("BT");
        sb.AppendLine("/F1 12 Tf");
        sb.AppendLine("50 800 Td");
        sb.AppendLine("(Vending machines) Tj");
        sb.AppendLine("T*" );

        foreach (var row in rows)
        {
            var text = $"{row.Id} {row.Name} {row.Model} {row.Company}";
            sb.AppendLine($"({ToAscii(text)}) Tj");
            sb.AppendLine("T*");
        }

        sb.AppendLine("ET");
        return sb.ToString();
    }

    private static string ToAscii(string value)
    {
        // Убираем не-ASCII символы, чтобы PDF не ломался.
        var sb = new StringBuilder();
        foreach (var ch in value)
        {
            sb.Append(ch <= 127 ? ch : '?');
        }

        return sb.ToString().Replace("(", "[").Replace(")", "]");
    }
}
