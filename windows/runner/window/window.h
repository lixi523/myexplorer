#ifndef MYEXPLORER_WINDOW_H_
#define MYEXPLORER_WINDOW_H_

#include <windows.h>

namespace myexplorer_window {

// Flags for configure().
constexpr unsigned int kCustomFrame    = 0x1;
constexpr unsigned int kHideOnStartup  = 0x2;

void configure(unsigned int flags);
HWND getAppWindow();

void setMinSize(int width, int height);
void setWindowCanBeShown(bool value);
bool dragAppWindow();

}  // namespace myexplorer_window

#endif  // MYEXPLORER_WINDOW_H_
