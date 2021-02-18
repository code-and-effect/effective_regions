# This object just holds an asset file
# There is a single `global` ck asset in which we use for the ckeditor uploads form

module Effective
  class CkAsset < ActiveRecord::Base
    self.table_name = EffectiveRegions.ck_assets_table_name.to_s

    # Only the global one
    has_many_attached :files

    # The instance ones will have just one file
    has_one_attached :file

    effective_resource do
      global :boolean
    end

    def self.global
      CkAsset.where(global: true).first || CkAsset.create!(global: true)
    end
  end
end
