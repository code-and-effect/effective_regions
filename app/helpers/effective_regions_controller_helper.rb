module EffectiveRegionsControllerHelper
  def effectively_editing?
    @effectively_editing ||= (
      request.fullpath.include?('edit=true') &&
      EffectiveResources.authorized?(controller, :edit, Effective::Region.new)
    )
  end
  alias_method :effectively_editting?, :effectively_editing?
end
