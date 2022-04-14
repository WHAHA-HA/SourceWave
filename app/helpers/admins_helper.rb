module AdminsHelper
  def activate_deactivate(user)
    if user.active?
      link_to(
        'Deactivate',
        make_user_inactive_admins_path(user_id: user.id),
        class: 'btn btn-danger'
      )
    else
      link_to(
        'Make Active',
        make_user_active_admins_path(user_id: user.id),
        class: 'btn btn-primary'
      )
    end
  end
end
