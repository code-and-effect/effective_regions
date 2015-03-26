module EffectiveRegionsControllerHelper
  def effectively_editing?
    @effectively_editing ||= (
      request.fullpath.include?('edit=true') &&
      (EffectiveRegions.authorized?(controller, :edit, Effective::Region.new()) rescue false)
    )
  end
  alias_method :effectively_editting?, :effectively_editing?
end
