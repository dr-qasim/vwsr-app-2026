using System.Linq;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace VWSR.Web.Pages;

public sealed class CalendarModel : PageModel
{
    public string? Filter { get; private set; }
    public List<CalendarItem> Items { get; } = new();

    public void OnGet(string? type)
    {
        // Минимальная логика: имитируем данные, чтобы показать цветовую маркировку.
        Filter = type;

        var data = new List<CalendarItem>
        {
            new("ТА-01", DateTime.Today.AddDays(1), "Плановое ТО", "table-success", "Плановое обслуживание"),
            new("ТА-02", DateTime.Today.AddDays(3), "Срок < 5 дней", "table-warning", "Приближается срок"),
            new("ТА-03", DateTime.Today.AddDays(-2), "Просрочено", "table-danger", "Просрочено"),
        };

        if (string.IsNullOrWhiteSpace(Filter))
        {
            Items.AddRange(data);
            return;
        }

        Items.AddRange(data.Where(i => i.FilterKey == Filter));
    }

    public sealed class CalendarItem
    {
        public CalendarItem(string machineName, DateTime date, string statusText, string cssClass, string tooltip)
        {
            MachineName = machineName;
            Date = date;
            StatusText = statusText;
            CssClass = cssClass;
            Tooltip = tooltip;
            FilterKey = cssClass switch
            {
                "table-success" => "plan",
                "table-warning" => "soon",
                "table-danger" => "overdue",
                _ => ""
            };
        }

        public string MachineName { get; }
        public DateTime Date { get; }
        public string StatusText { get; }
        public string CssClass { get; }
        public string Tooltip { get; }
        public string FilterKey { get; }
    }
}
