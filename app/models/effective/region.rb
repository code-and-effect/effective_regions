module Effective
  class Region < ActiveRecord::Base
    #include ActiveModel::ForbiddenAttributesProtection

    self.table_name = EffectiveRegions.regions_table_name.to_s

    belongs_to :regionable, :polymorphic => true

    structure do
      title             :string, :validates => [:presence]
      content           :text
      snippets          :text

      timestamps
    end

    serialize :snippets, Hash

    scope :global, -> { where('regionable_type IS NULL').where('regionable_id IS NULL') }

    def snippets
      self[:snippets] || HashWithIndifferentAccess.new()
    end
  end
end




