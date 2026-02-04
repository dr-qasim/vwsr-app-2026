using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace VWSR.Web.Pages;

public sealed class LogoutModel : PageModel
{
    public IActionResult OnGet()
    {
        // Просто очищаем сессию.
        HttpContext.Session.Clear();
        return RedirectToPage("/Login");
    }
}
