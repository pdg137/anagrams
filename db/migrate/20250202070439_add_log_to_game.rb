class AddLogToGame < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :log, :text
  end
end
