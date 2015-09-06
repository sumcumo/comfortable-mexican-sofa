class Comfy::Cms::Variant < ActiveRecord::Base
  self.table_name = 'comfy_cms_variants'

  belongs_to :site

  validates :label,
    :presence   => true,
    :uniqueness => true
  validates :hierarchy,
    :presence   => true
  validates :hostname,
    :presence   => true,
    :uniqueness => { :scope => :hostname },
    :format     => { :with => /\A[\w\.\-]+(?:\:\d+)?\z/ }
end
