class UpgradeTo11291 < ActiveRecord::Migration
  def self.up
    create_table :comfy_cms_variants, :force => true do |t|
      t.belongs_to :site
      t.string  :label
      t.string  :hostname
      t.integer :hierarchy
      t.boolean :is_default, default: false
      t.timestamps
    end
    add_index :comfy_cms_variants, :label
    add_column :comfy_cms_pages, :variant_id, :integer
    add_column :comfy_cms_pages, :page_group, :integer
  end

  def self.down
    remove_column :comfy_cms_pages, :variant_id, :integer
    remove_column :comfy_cms_pages, :page_group, :integer
    remove_index :comfy_cms_variants, :label
    drop_table :comfy_cms_variants
  end
end
