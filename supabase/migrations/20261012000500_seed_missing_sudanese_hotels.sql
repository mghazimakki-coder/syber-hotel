-- Seed missing Sudanese hotel listings and clearly labeled demo apartments.
-- Existing hotel and apartment records are never changed or deleted.
do $$
declare
  hotel record;
  apartment record;
  v_hotel_id uuid;
  v_demo_unit_count integer;
begin
  for hotel in
    select *
    from (values
      (
        'Al Salam Hotel Khartoum',
        'al salam hotel',
        'فندق السلام الخرطوم',
        'Khartoum, Sudan',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=85',
        180000::numeric, 220000::numeric, 260000::numeric
      ),
      (
        'Corinthia Hotel Khartoum',
        'corinthia',
        'فندق كورنثيا الخرطوم',
        'Nile Street, Khartoum, Sudan',
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1400&q=85',
        320000::numeric, 380000::numeric, 450000::numeric
      ),
      (
        'Acropole Hotel',
        'acropole',
        'فندق أكروبول',
        'Khartoum, Sudan',
        'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1400&q=85',
        120000::numeric, 150000::numeric, 180000::numeric
      ),
      (
        'Grand Holiday Villa Hotel',
        'grand holiday villa',
        'فندق جراند هوليداي فيلا',
        'Nile Street, Khartoum, Sudan',
        'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1400&q=85',
        200000::numeric, 240000::numeric, 290000::numeric
      ),
      (
        'EWA Khartoum Hotel & Apartments',
        'ewa khartoum',
        'فندق إيوا الخرطوم والشقق',
        'Khartoum, Sudan',
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1400&q=85',
        190000::numeric, 230000::numeric, 280000::numeric
      )
    ) as hotels(
      english_name,
      english_alias,
      arabic_name,
      location,
      image_url,
      price_standard,
      price_family,
      price_spacious
    )
  loop
    select h.id
      into v_hotel_id
      from public.hotels h
      where lower(btrim(h.location)) = lower(btrim(hotel.location))
        and (
          lower(btrim(h.name)) = any(array[
            lower(hotel.english_name),
            lower(hotel.arabic_name),
            lower(hotel.english_name || ' | ' || hotel.arabic_name),
            lower(hotel.arabic_name || ' | ' || hotel.english_name),
            lower(hotel.arabic_name || ' (' || hotel.english_name || ')'),
            lower(hotel.english_name || ' - ' || hotel.arabic_name)
          ])
          or lower(btrim(h.name)) like '%' || lower(hotel.english_alias) || '%'
          or lower(btrim(h.name)) like '%' || lower(hotel.arabic_name) || '%'
        )
      order by h.id
      limit 1;

    if v_hotel_id is null then
      insert into public.hotels (name, location, description, image_url)
      values (
        hotel.arabic_name || ' | ' || hotel.english_name,
        hotel.location,
        format(
          '%s (%s), %s. الفندق مدرج للتعريف فقط. الصورة تمثيلية ثابتة؛ الشقق والأسعار في Syber Hotel بيانات تجريبية وليست وحدات أو عروضاً فعلية من الفندق.',
          hotel.arabic_name,
          hotel.english_name,
          hotel.location
        ),
        hotel.image_url
      )
      returning id into v_hotel_id;
    end if;

    for apartment in
      select *
      from (values
        (
          'شقة تجريبية قياسية | Demo Standard Apartment',
          'شقة تجريبية ١ - قياسية | Demo Apartment 1 - Standard',
          hotel.price_standard,
          'وحدة وسعر تجريبيان لاختبار Syber Hotel؛ لا يمثلان وحدة فعلية أو توافراً مؤكداً لدى الفندق.',
          1,
          2
        ),
        (
          'شقة تجريبية عائلية | Demo Family Apartment',
          'شقة تجريبية ٢ - عائلية | Demo Apartment 2 - Family',
          hotel.price_family,
          'وحدة وسعر تجريبيان لاختبار Syber Hotel؛ لا يمثلان وحدة فعلية أو توافراً مؤكداً لدى الفندق.',
          2,
          4
        ),
        (
          'شقة تجريبية واسعة | Demo Spacious Apartment',
          'شقة تجريبية ٣ - واسعة | Demo Apartment 3 - Spacious',
          hotel.price_spacious,
          'وحدة وسعر تجريبيان لاختبار Syber Hotel؛ لا يمثلان وحدة فعلية أو توافراً مؤكداً لدى الفندق.',
          3,
          6
        )
      ) as apartments(
        name,
        legacy_name,
        price,
        description,
        number_of_rooms,
        number_of_beds
      )
    loop
      if not exists (
        select 1
        from public.apartments a
        where a.hotel_id = v_hotel_id
          and lower(btrim(a.name)) = any(array[
            lower(apartment.name),
            lower(apartment.legacy_name)
          ])
      ) then
        insert into public.apartments (
          hotel_id,
          name,
          description,
          price,
          image_url,
          status
        )
        values (
          v_hotel_id,
          apartment.name,
          apartment.description,
          apartment.price,
          hotel.image_url,
          'available'
        );
      end if;
    end loop;

    select count(*)
      into v_demo_unit_count
      from public.apartments a
      where a.hotel_id = v_hotel_id
        and lower(btrim(a.name)) = any(array[
          lower('شقة تجريبية قياسية | Demo Standard Apartment'),
          lower('شقة تجريبية ١ - قياسية | Demo Apartment 1 - Standard'),
          lower('شقة تجريبية عائلية | Demo Family Apartment'),
          lower('شقة تجريبية ٢ - عائلية | Demo Apartment 2 - Family'),
          lower('شقة تجريبية واسعة | Demo Spacious Apartment'),
          lower('شقة تجريبية ٣ - واسعة | Demo Apartment 3 - Spacious')
        ]);

    if v_demo_unit_count < 3 then
      raise exception 'Expected three demo apartments for hotel %', v_hotel_id;
    end if;

    v_hotel_id := null;
  end loop;
end;
$$;
