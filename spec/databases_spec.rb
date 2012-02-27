require 'chefspec'

describe 'fanfare::databases' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'fanfare::databases' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
