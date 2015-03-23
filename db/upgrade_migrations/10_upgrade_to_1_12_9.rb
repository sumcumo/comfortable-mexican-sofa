class UpgradeTo1129 < ActiveRecord::Migration
  def self.up
    add_column :comfy_cms_pages, :is_withdrawn, :boolean, :default => false
    add_column :comfy_cms_pages, :newest_draft_timestamp, :datetime, :null => true
  end

  def self.down
    remove_column :comfy_cms_pages, :is_withdrawn, :boolean
    remove_column :comfy_cms_pages, :newest_draft_timestamp, :datetime
  end
end
