class AddStatusToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :status, :string
  end
end
