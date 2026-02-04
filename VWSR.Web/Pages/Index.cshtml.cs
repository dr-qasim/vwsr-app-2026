using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace VWSR.Web.Pages;

public class IndexModel : PageModel
{
    public IActionResult OnGet()
    {
        // Чтобы не показывать "главную" до входа, отправляем на страницу логина.
        var token = HttpContext.Session.GetString("AccessToken");
        if (string.IsNullOrWhiteSpace(token))
        {
            return RedirectToPage("/Login");
        }

        // Если пользователь уже вошел - можно сразу вести в основной раздел.
        return RedirectToPage("/VendingMachines");
    }
}
