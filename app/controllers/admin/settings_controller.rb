class Admin::SettingsController < Admin::BaseController
  def show
    @ai_hints_enabled = AppSetting.ai_hints_enabled?
  end

  def update
    case params[:setting]
    when "ai_hints_enabled"
      params[:value] == "true" ? AppSetting.enable_ai_hints! : AppSetting.disable_ai_hints!
    end
    redirect_to admin_settings_path, notice: "Setting updated."
  end
end
