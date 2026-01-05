module BackupScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_backup
  end

  private
    def set_backup
      @backup = Backup.find(params[:backup_id])
    end
end
