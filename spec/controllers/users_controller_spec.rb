require 'spec_helper'
require 'fabrication'
require 'faker'

describe UsersController do
  describe 'GET new' do
    it " set a new variable @user" do 
      get :new
      expect(assigns(:user)).to be_instance_of(User)
      expect(assigns(:user)).to be_a_new(User)
    end
    it "render a template of 'new'" do
      get :new
      expect(response).to render_template('new')
    end
  end
  context "send a email" do
    before do
      charge = double('charge')
      charge.stub(:successful?).and_return(true)
      StripeWrapper::Charge.stub(:create).and_return(charge)
    end
    after {ActionMailer::Base.deliveries.clear}
    before {ActionMailer::Base.deliveries.clear}
    it "sends a email with valid input" do
      post :create, user: {name: "Bob", password: "123456", email:"user@email.com"}
      expect(ActionMailer::Base.deliveries).not_to be_nil
    end
    it "sends a email to the right receiver with valid input" do
      post :create, user: {name: "Bob", password: "123456", email:"user@email.com"}
      expect(ActionMailer::Base.deliveries.last.to).to eq(["user@email.com"])
    end
    it "sends a email to the right context with valid input"  do
      post :create, user: {name: "Bob", password: "123456", email:"user@email.com"}
      expect(ActionMailer::Base.deliveries.last.body).to include("Welcome to MyFlix, Bob!")
    end
    it "doesnot send an email with invalid input" do
      post :create, user: {email:"John@email.com"}
      expect(ActionMailer::Base.deliveries).to eq([])
    end
  end
  describe "POST create" do
    context "with valid personal info and valid card" do
      before do
        charge = double('charge')
        charge.stub(:successful?).and_return(true)
        StripeWrapper::Charge.stub(:create).and_return(charge)
      end
      it "set a variable @categories" do
        cat1 = Fabricate(:category)
        post :create, user: {name:"Bob", password: "123456", email:'user@email.com'}
        expect(assigns(:categories)).to eq(Category.all)
      end
      it "set a variable @user" do 
        post :create, user: {name: "Bob", password: "123456", email:"user@email.com"}
        expect(assigns(:user)).to be_a_instance_of(User)
      end
      it "redirects to a sign in url when @user is valid" do
        post :create, user: {name: "Bob", password: "123456", email: Faker::Internet.email}
        expect(assigns(:user)).not_to be_a_new(User)
        expect(response).to redirect_to sign_in_path
      end
      it "creates a leadership and followership with invitor when @user is valid and there is invitor" do
        budda = Fabricate(:user)
        budda.update_column(:token, "7890")
        post :create, user: {name: "Bob", password: "123456", email: Faker::Internet.email}, token: "7890"
        expect(User.last.leaders).to include(budda)
        expect(User.last.followers).to include(budda)  
      end
      it " creates the invitor token to ensure an invitation only invite a user." do
        budda = Fabricate(:user)
        budda.update_column(:token, "7890")
        post :create, user: {name: "Bob", password: "123456", email: Faker::Internet.email}, token: "7890"
        post :create, user: {name: "seal", password: "123456", email: Faker::Internet.email}, token: "7890"
        expect(User.last.leaders).not_to include(budda)
      end
    end
    context "with valid personal info and invalid card" do
      before do
        charge = double('charge')
        charge.stub(:successful?).and_return(false)
        StripeWrapper::Charge.stub(:create).and_return(charge)
        charge.stub(:error_message).and_return("fail")
      end
      it "set a variable @categories" do
        post :create, user: {name:"Bob", password: "123456", email:'user@email.com'}
        expect(User.count).to eq(0)
      end
      it "redirects to register page" do
        post :create, user: {name:"Bob", password: "123456", email:'user@email.com'}
        expect(response).to redirect_to register_path
      end
      it "sets the flash error message" do
        post :create, user: {name:"Bob", password: "123456", email:'user@email.com'}
        expect(flash[:danger]).to be_present
      end
    end
    context "invalid personal info" do
      before do
        charge = double('charge')
        charge.stub(:successful?).and_return(true)
        StripeWrapper::Charge.stub(:create).and_return(charge)
      end
      it "does not create a user" do
        post :create, user: {name:"Bob", password: "123456"}
        expect(User.count).to eq(0)
      end
      it "does not charge the card" do
        post :create, user: {name:"Bob", password: "123456"}
        StripeWrapper::Charge.should_not_receive(:create)
      end
      it "renders a template when @user is not valid" do
        User.create(name: "Bob", password: "123456", email: "user1@email.com")
        post :create, user: {name: "Bob", password: "123456", email: "user1@email.com"}
        expect(response).to render_template('pages/front')
      end
    end
  end

  describe "GET show" do
    let(:bob) {Fabricate(:user)}
    before do 
      set_current_user_alice
    end
    it "sets a variable @user" do
      get :show, id: bob.token
      expect(assigns(:user).name).to eq(bob.name)
    end
    it "renders show template" do
      get :show, id:bob.id
      expect(response).to render_template('users/show')
    end
    it "redirects a sign in page when unauthenticated user" do
      set_current_user_nil
      get :show, id:bob.id
      expect(response).to redirect_to sign_in_path
    end
  end

end