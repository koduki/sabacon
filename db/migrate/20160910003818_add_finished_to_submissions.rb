class AddFinishedToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :finished, :boolean, default: false, null: false
  end
end
