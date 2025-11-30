class MakeGameLogNotNull < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE games SET log = '' WHERE log IS NULL;
    SQL
    change_column_default :games, :log, ''
    change_column_null :games, :log, false
  end

  def down
    change_column_null :games, :log, true
    change_column_default :games, :log, nil
  end
end