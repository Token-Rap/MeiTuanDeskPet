#include "flutter_window.h"

#include <optional>
#include <flutter/standard_method_codec.h>
#include "resource.h"

namespace {
constexpr UINT kTrayMessage = WM_APP + 17;
constexpr UINT kShow = 101, kSwitch = 102, kUpdate = 103, kAuto = 104, kExit = 105;
std::wstring Wide(const std::string& text) {
  const int size = MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
  std::wstring value(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), value.data(), size);
  return value;
}
}  // namespace

#include "flutter/generated_plugin_registrant.h"

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
  desktop_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "meituan/desktop",
      &flutter::StandardMethodCodec::GetInstance());
  desktop_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "initialize") {
      DWORD automatic = 1, size = sizeof(automatic);
      RegGetValueW(HKEY_CURRENT_USER, L"Software\\MeiTuanDeskPet", L"AutomaticUpdates",
                   RRF_RT_REG_DWORD, nullptr, &automatic, &size);
      automatic_ = automatic != 0;
      AddTrayIcon();
      const std::string version = std::to_string(FLUTTER_VERSION_MAJOR) + "." +
          std::to_string(FLUTTER_VERSION_MINOR) + "." + std::to_string(FLUTTER_VERSION_PATCH);
      result->Success(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("version"), flutter::EncodableValue(version)},
        {flutter::EncodableValue("build"), flutter::EncodableValue(FLUTTER_VERSION_BUILD)},
        {flutter::EncodableValue("automatic"), flutter::EncodableValue(automatic_)}
      }));
    } else if (call.method_name() == "setAutomatic") {
      automatic_ = std::get<bool>(*call.arguments());
      const DWORD value = automatic_ ? 1 : 0;
      RegSetKeyValueW(HKEY_CURRENT_USER, L"Software\\MeiTuanDeskPet", L"AutomaticUpdates",
                      REG_DWORD, &value, sizeof(value));
      result->Success();
    } else if (call.method_name() == "notify") {
      Notify(Wide(std::get<std::string>(*call.arguments())));
      result->Success();
    } else if (call.method_name() == "install") {
      const auto file = Wide(std::get<std::string>(*call.arguments()));
      wchar_t executable[MAX_PATH]{};
      GetModuleFileNameW(nullptr, executable, MAX_PATH);
      const std::wstring path(executable);
      const auto directory = path.substr(0, path.find_last_of(L"\\"));
      const std::wstring parameters = L"/SILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS /DIR=\"" + directory + L"\"";
      SHELLEXECUTEINFOW execute{};
      execute.cbSize = sizeof(execute);
      execute.fMask = SEE_MASK_NOCLOSEPROCESS;
      execute.hwnd = GetHandle();
      execute.lpVerb = L"open";
      execute.lpFile = file.c_str();
      execute.lpParameters = parameters.c_str();
      execute.nShow = SW_SHOWNORMAL;
      installing_ = true;
      const bool success = ShellExecuteExW(&execute) != FALSE;
      installer_process_ = execute.hProcess;
      if (success && installer_process_) SetTimer(GetHandle(), 91, 1000, nullptr);
      if (!success) installing_ = false;
      result->Success(flutter::EncodableValue(success));
    } else {
      result->NotImplemented();
    }
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

void FlutterWindow::AddTrayIcon() {
  tray_.cbSize = sizeof(tray_);
  tray_.hWnd = GetHandle();
  tray_.uID = 1;
  tray_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  tray_.uCallbackMessage = kTrayMessage;
  tray_.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(tray_.szTip, L"小美与小团 · MeiTuanDeskPet");
  Shell_NotifyIconW(NIM_ADD, &tray_);
}

void FlutterWindow::Notify(const std::wstring& message) {
  tray_.uFlags = NIF_INFO;
  wcscpy_s(tray_.szInfoTitle, L"小美与小团");
  wcsncpy_s(tray_.szInfo, message.c_str(), _TRUNCATE);
  tray_.dwInfoFlags = NIIF_INFO;
  Shell_NotifyIconW(NIM_MODIFY, &tray_);
}

void FlutterWindow::ShowTrayMenu() {
  HMENU menu = CreatePopupMenu();
  AppendMenuW(menu, MF_STRING, kShow, IsWindowVisible(GetHandle()) ? L"隐藏猫咪" : L"显示猫咪");
  AppendMenuW(menu, MF_STRING, kSwitch, L"切换小美 / 小团");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kUpdate, L"检查并安装更新");
  AppendMenuW(menu, MF_STRING | (automatic_ ? MF_CHECKED : MF_UNCHECKED), kAuto, L"自动更新");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kExit, L"退出");
  POINT point{};
  GetCursorPos(&point);
  SetForegroundWindow(GetHandle());
  const UINT command = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON,
      point.x, point.y, 0, GetHandle(), nullptr);
  DestroyMenu(menu);
  PostMessage(GetHandle(), WM_NULL, 0, 0);
  if (command == kShow) {
    ShowWindow(GetHandle(), IsWindowVisible(GetHandle()) ? SW_HIDE : SW_SHOW);
  } else if (command == kExit) {
    exiting_ = true;
    PostMessage(GetHandle(), WM_CLOSE, 0, 0);
  } else if (desktop_channel_) {
    const char* method = command == kSwitch ? "switchCat" :
                         command == kUpdate ? "checkUpdate" :
                         command == kAuto ? "toggleAuto" : nullptr;
    if (method) desktop_channel_->InvokeMethod(method, nullptr);
  }
}

void FlutterWindow::OnDestroy() {
  KillTimer(GetHandle(), 91);
  if (installer_process_) CloseHandle(installer_process_);
  if (tray_.hWnd) Shell_NotifyIconW(NIM_DELETE, &tray_);
  desktop_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_TIMER && wparam == 91 && installer_process_) {
    DWORD code = STILL_ACTIVE;
    if (GetExitCodeProcess(installer_process_, &code) && code != STILL_ACTIVE) {
      KillTimer(hwnd, 91);
      CloseHandle(installer_process_);
      installer_process_ = nullptr;
      installing_ = false;
      if (desktop_channel_) desktop_channel_->InvokeMethod("installFinished", std::make_unique<flutter::EncodableValue>(static_cast<int>(code)));
    }
    return 0;
  }
  static const UINT taskbar_created = RegisterWindowMessageW(L"TaskbarCreated");
  if (message == taskbar_created && tray_.hWnd) { AddTrayIcon(); return 0; }
  if (message == kTrayMessage) {
    if (lparam == WM_RBUTTONUP) ShowTrayMenu();
    if (lparam == WM_LBUTTONDBLCLK) { ShowWindow(hwnd, SW_SHOW); SetForegroundWindow(hwnd); }
    if (lparam == NIN_BALLOONUSERCLICK && desktop_channel_) desktop_channel_->InvokeMethod("checkUpdate", nullptr);
    return 0;
  }
  // Let Windows Restart Manager close the running image during an update.
  if (message == WM_QUERYENDSESSION) return TRUE;
  if (message == WM_ENDSESSION && wparam && (lparam & ENDSESSION_CLOSEAPP)) {
    exiting_ = true;
    Destroy();
    return 0;
  }
  if (message == WM_CLOSE && !exiting_ && !installing_) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }
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
