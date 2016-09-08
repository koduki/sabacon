class CreateSubmissions < ActiveRecord::Migration[5.0]
  def change
    create_table :submissions do |t|
      t.integer :problem
      t.string :repos_url
      t.string :tag

      t.timestamps
    end
  end
end
