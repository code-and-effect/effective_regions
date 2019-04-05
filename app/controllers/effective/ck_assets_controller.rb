module Effective
  class CkAssetsController < ApplicationController
    layout false

    include Effective::CrudController

    resource_scope -> { Effective::CkAsset.all.with_attached_files }

    def permitted_params
      params.require(:effective_ck_asset).permit!
    end

  end
end

