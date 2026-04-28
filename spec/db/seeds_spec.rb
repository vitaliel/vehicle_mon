require 'rails_helper'

RSpec.describe 'db/seeds.rb', type: :model do
  let(:seed_file) { Rails.root.join('db', 'seeds.rb') }
  let(:canonical_names) do
    %w[
      Air\ Filter
      Brake\ Pads
      Engine\ Oil
      Spark\ Plugs
      Tires
      Transmission\ Fluid
    ]
  end

  before { ServiceType.delete_all }

  it 'creates exactly 6 ServiceType records on first run' do
    load seed_file
    expect(ServiceType.count).to eq(6)
  end

  it 'creates records with the canonical names' do
    load seed_file
    expect(ServiceType.pluck(:name).sort).to match_array(canonical_names)
  end

  it 'is idempotent — second run keeps count at 6 (no duplicates)' do
    load seed_file
    load seed_file
    expect(ServiceType.count).to eq(6)
  end
end
