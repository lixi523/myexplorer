#include "window_api.h"

#include <windows.h>

#include "window.h"

extern "C" {

void myexplorer_window_configure(unsigned int flags) {
  myexplorer_window::configure(flags);
}

void myexplorer_window_set_min_size(int width, int height) {
  myexplorer_window::setMinSize(width, height);
}

void myexplorer_window_show() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (!hwnd) return;
  myexplorer_window::setWindowCanBeShown(true);
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
}

void myexplorer_window_hide() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (!hwnd) return;
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOSIZE | SWP_NOMOVE | SWP_HIDEWINDOW);
}

void myexplorer_window_minimize() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_MINIMIZE, 0);
}

void myexplorer_window_maximize() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
}

void myexplorer_window_restore() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_RESTORE, 0);
}

void myexplorer_window_close() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0);
}

int myexplorer_window_is_maximized() {
  HWND hwnd = myexplorer_window::getAppWindow();
  return (hwnd && IsZoomed(hwnd)) ? 1 : 0;
}

int myexplorer_window_is_visible() {
  HWND hwnd = myexplorer_window::getAppWindow();
  return (hwnd && IsWindowVisible(hwnd)) ? 1 : 0;
}

void myexplorer_window_start_dragging() { myexplorer_window::dragAppWindow(); }

void myexplorer_window_set_title(const wchar_t* title) {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (hwnd && title) SetWindowTextW(hwnd, title);
}

void myexplorer_window_set_size(int width, int height) {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (!hwnd) return;
  UINT dpi = GetDpiForWindow(hwnd);
  double scale = dpi / 96.0;
  int w = static_cast<int>(width * scale);
  int h = static_cast<int>(height * scale);
  SetWindowPos(hwnd, nullptr, 0, 0, w, h, SWP_NOMOVE | SWP_NOZORDER);
}

void myexplorer_window_get_size(int* width, int* height) {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (!hwnd || !width || !height) return;
  RECT rc;
  GetWindowRect(hwnd, &rc);
  UINT dpi = GetDpiForWindow(hwnd);
  double scale = dpi / 96.0;
  *width = static_cast<int>((rc.right - rc.left) / scale);
  *height = static_cast<int>((rc.bottom - rc.top) / scale);
}

void myexplorer_window_center() {
  HWND hwnd = myexplorer_window::getAppWindow();
  if (!hwnd) return;
  RECT rc;
  GetWindowRect(hwnd, &rc);
  int w = rc.right - rc.left;
  int h = rc.bottom - rc.top;
  HMONITOR mon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info = {};
  info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfoW(mon, &info)) return;
  int mw = info.rcWork.right - info.rcWork.left;
  int mh = info.rcWork.bottom - info.rcWork.top;
  int x = info.rcWork.left + (mw - w) / 2;
  int y = info.rcWork.top + (mh - h) / 2;
  SetWindowPos(hwnd, nullptr, x, y, 0, 0,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSIZE);
}

}  // extern "C"
