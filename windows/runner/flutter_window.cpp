#include "flutter_window.h"

#include <optional>
#include <string>
#include <windows.h>
#include <winhttp.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include "flutter/generated_plugin_registrant.h"
#include <desktop_multi_window/desktop_multi_window_plugin.h>

namespace {

std::string wide_to_utf8(const wchar_t* value) {
  if (value == nullptr || *value == L'\0') {
    return {};
  }

  const int size = WideCharToMultiByte(
      CP_UTF8, 0, value, -1, nullptr, 0, nullptr, nullptr);
  if (size <= 1) {
    return {};
  }

  std::string result(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(
      CP_UTF8, 0, value, -1, result.data(), size, nullptr, nullptr);
  result.resize(static_cast<size_t>(size - 1));
  return result;
}

std::string get_system_proxy() {
  WINHTTP_CURRENT_USER_IE_PROXY_CONFIG config{};
  if (!WinHttpGetIEProxyConfigForCurrentUser(&config)) {
    return {};
  }

  const std::string proxy = wide_to_utf8(config.lpszProxy);
  if (config.lpszAutoConfigUrl != nullptr) {
    GlobalFree(config.lpszAutoConfigUrl);
  }
  if (config.lpszProxy != nullptr) {
    GlobalFree(config.lpszProxy);
  }
  if (config.lpszProxyBypass != nullptr) {
    GlobalFree(config.lpszProxyBypass);
  }
  return proxy;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  const flutter::MethodChannel<> system_proxy_channel(
      flutter_controller_->engine()->messenger(),
      "com.meteor.kikoeruflutter/system_proxy",
      &flutter::StandardMethodCodec::GetInstance());
  system_proxy_channel.SetMethodCallHandler(
      [](const flutter::MethodCall<>& call,
         const std::unique_ptr<flutter::MethodResult<>>& result) {
        if (call.method_name() == "getSystemProxy") {
          result->Success(flutter::EncodableValue(get_system_proxy()));
          return;
        }
        result->NotImplemented();
      });

  DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
    auto *flutter_view_controller =
        reinterpret_cast<flutter::FlutterViewController *>(controller);
    auto *registry = flutter_view_controller->engine();
    RegisterPlugins(registry);
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
