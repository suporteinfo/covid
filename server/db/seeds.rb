def fake_historical hospital
  30.times do |i|
    bed_state = BedState.create!(
      date: (30 - i).days.ago, hospital: hospital
    )

    [true, false].each do |using_ventilator|
      Bed::TYPES.each do |_label, value|
        BedStateDetail.create!(
          using_ventilator: using_ventilator,

          bed_state_id: bed_state.id,
          bed_type: value,
          status_free: rand(1000),
          status_busy: rand(1000),
          status_unavailable: rand(1000),
        )
      end
    end
  end
end

if Hospital.none?
  rand_geocoded = -> { ([-1, 1].sample * rand(0..1.0).round(6)) }
  cities = City.offset(rand(35)).limit(3)

  city = City.find_by_slug('jaragua')

  unless city.nil?
    [
      {
        name: 'Hospital e Maternidade Jaraguá',
        slug: 'maternidade',
        hospital_type: 2,
        city: city,
        latitude: -15.7513041,
        longitude: -49.3341571
      },
      {
        name: 'Hospital Estadual de Jaraguá Sandino de Amorim',
        slug: 'hospital-estadual',
        hospital_type: 1,
        city: city,
        latitude: -15.7443824,
        longitude: -49.3298054
      }
    ].each do |hospital|
      hospital = Hospital.create!(hospital)

      fake_historical(hospital)
    end
  end

  # DataBridge::Unimed.new.get_data.save!
end

if CovidCase.none?
  City.all.each do |city|
    30.times do |i|
      deaths = rand(500)
      cureds = rand(500)
      total = cureds + deaths

      covid_case = CovidCase.create!(
        city: city,
        total: rand(total..(total + 500)),
        deaths: deaths,
        cureds: cureds,
        reference_date: i.days.ago
      )
    end
  end
end

