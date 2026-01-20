class AddNotifyOnSuccessToNotifiers < ActiveRecord::Migration[8.1]
  def change
    add_column :notifiers, :notify_on_success, :boolean, default: false, null: false
    add_column :notifiers, :notify_on_failure, :boolean, default: true, null: false
  end
end
