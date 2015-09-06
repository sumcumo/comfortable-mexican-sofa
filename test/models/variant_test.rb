# encoding: utf-8

require_relative '../test_helper'

class CmsVariantTest < ActiveSupport::TestCase

  def test_validation
    variant = Comfy::Cms::Variant.new
    assert variant.invalid?
    assert_has_errors_on variant, [:label, :hostname, :hierarchy]

    # variant = Comfy::Cms::Variant.new(:identifier => 'test', :hostname => 'http://variant.host')
    # assert variant.invalid?
    # assert_has_errors_on variant, :hostname
    #
    # variant = Comfy::Cms::Variant.new(:identifier => comfy_cms_variants(:default).identifier, :hostname => 'variant.host')
    # assert variant.invalid?
    # assert_has_errors_on variant, :identifier
    #
    # variant = Comfy::Cms::Variant.new(:identifier => 'test', :hostname => 'variant.host')
    # assert variant.valid?, variant.errors.inspect
    #
    # variant = Comfy::Cms::Variant.new(:identifier => 'test', :hostname => 'localhost:3000')
    # assert variant.valid?, site.errors.inspect
  end
end
