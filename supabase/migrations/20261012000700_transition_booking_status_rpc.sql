-- Replace the text overload with the booking_status enum RPC expected by Flutter.
drop function if exists public.transition_booking_status(uuid, text);

create or replace function public.transition_booking_status(
  p_booking_id uuid,
  p_next_status public.booking_status
)
returns public.booking_status
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  actor_role text;
  assigned_hotel uuid;
  current_status public.booking_status;
  updated_status public.booking_status;
begin
  actor_role := coalesce(public.get_my_role()::text, '');
  if auth.uid() is null or actor_role not in ('manager', 'receptionist') then
    raise exception using
      errcode = '42501',
      message = 'booking_transition_not_permitted';
  end if;

  assigned_hotel := public.get_my_hotel();
  if assigned_hotel is null then
    raise exception using
      errcode = '42501',
      message = 'booking_transition_not_permitted';
  end if;

  select b.status
    into current_status
    from public.bookings b
    where b.id = p_booking_id
      and b.hotel_id = assigned_hotel
    for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'booking_not_found';
  end if;

  if not (
    (current_status = 'pending' and p_next_status in ('confirmed', 'cancelled'))
    or (current_status = 'confirmed' and p_next_status in ('checked_in', 'cancelled'))
    or (current_status = 'checked_in' and p_next_status in ('checked_out', 'cancelled'))
  ) then
    raise exception using errcode = 'P0001', message = 'invalid_booking_transition';
  end if;

  update public.bookings
    set status = p_next_status
    where id = p_booking_id
      and hotel_id = assigned_hotel
    returning status into updated_status;

  return updated_status;
end;
$$;

revoke all on function public.transition_booking_status(uuid, public.booking_status)
  from public, anon, authenticated;
grant execute on function public.transition_booking_status(uuid, public.booking_status)
  to authenticated;

notify pgrst, 'reload schema';
