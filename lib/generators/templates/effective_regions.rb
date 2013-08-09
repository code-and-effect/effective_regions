EffectiveRegions.setup do |config|
  config.regions_table_name = :regions

  # Use CanCan: can?(action, resource)
  # Use effective_roles:  resource.roles_match_with?(current_user)
  config.authorization_method = Proc.new { |controller, action, resource| true }

end
