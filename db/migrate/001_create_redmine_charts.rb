class CreateRedmineCharts < ActiveRecord::Migration
  def change
    create_table :redmine_charts do |t|
      t.integer :project_id
      t.string :subject
      t.text :description
    end
  end
end
