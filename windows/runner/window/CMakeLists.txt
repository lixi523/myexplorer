add_library(myexplorer_window STATIC
  "window.cpp"
  "window_api.cpp"
)

apply_standard_settings(myexplorer_window)

set_target_properties(myexplorer_window PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_include_directories(myexplorer_window PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(myexplorer_window PRIVATE dwmapi Comctl32)
