using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace VWSR.Web.Pages;

public sealed class ScheduleModel : PageModel
{
    public List<ScheduleItem> DayItems { get; } = new();
    public List<ScheduleItem> WeekItems { get; } = new();

    public IActionResult OnGet()
    {
        // Без авторизации не показываем страницу.
        if (!IsAuthorized())
        {
            return RedirectToPage("/Login");
        }

        // Минимальные демо-данные (для критериев UI).
        DayItems.Add(new ScheduleItem("09:00", "Иванов", "ТО ТА-01"));
        DayItems.Add(new ScheduleItem("11:00", "Петров", "Ремонт ТА-03"));
        DayItems.Add(new ScheduleItem("15:00", "Сидоров", "Проверка ТА-02"));

        WeekItems.Add(new ScheduleItem("Пн", "Иванов", "ТО ТА-01"));
        WeekItems.Add(new ScheduleItem("Ср", "Петров", "Ремонт ТА-03"));
        WeekItems.Add(new ScheduleItem("Пт", "Сидоров", "Проверка ТА-02"));

        return Page();
    }

    public sealed record ScheduleItem(string Time, string Employee, string Task)
    {
        public string Day => Time;
    }

    private bool IsAuthorized()
    {
        return !string.IsNullOrWhiteSpace(HttpContext.Session.GetString("AccessToken"));
    }
}
