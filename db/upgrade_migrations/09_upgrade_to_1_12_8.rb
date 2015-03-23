class UpgradeTo1128 < ActiveRecord::Migration
  def self.up
    add_column :comfy_cms_pages, :last_published_revision_id, :integer, :null => true
    add_column :comfy_cms_pages, :scheduled_revision_id, :integer, :null => true
    add_column :comfy_cms_pages, :scheduled_revision_datetime, :datetime, :null => true
    add_index :comfy_cms_pages, :scheduled_revision_datetime
  end

  def self.down
    remove_column :comfy_cms_pages, :last_published_revision_id, :integer
    remove_column :comfy_cms_pages, :scheduled_revision_id, :integer
    remove_column :comfy_cms_pages, :scheduled_revision_datetime, :datetime
    remove_index :comfy_cms_pages, :scheduled_revision_datetime
  end
end
