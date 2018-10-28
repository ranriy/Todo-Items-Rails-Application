require_relative '../config/environment'
require 'rails_helper'

describe "Module #4: Navigation Tests", :type => :routing do
    include Capybara::DSL

    before :all do
        $continue = true
    end

    around :each do |example|
        if $continue
            $continue = false 
            example.run 
            $continue = true unless example.exception
        else
            example.skip
        end
    end

    context "rq04" do 
        scenario "TodoList scaffolding was generated and it was set as root path" do 
            visit (root_path) 
            expect(page.status_code).to eq(200)
            rootPage = page
            visit (todolists_path)
            expect(page.status_code).to eq(200)
            expect(page).to be(rootPage)
        end
        scenario "TodoItems is not directly accessible as it is nested in TodoList" do        
            visit ("/todoitems")
            expect(page.status_code).to eq(404)
        end
    end

    context "rq05" do

        before :all do    
            Todoitem.destroy_all
            Todolist.destroy_all
            User.destroy_all
            load "#{Rails.root}/db/seeds.rb"  
        end

        context "rq05b" do

            scenario "TodoList show page displays associated todo_items" do
                tl_id = Todolist.all.sample.id
                list_items = Todolist.find(tl_id).todoitems
                visit(todolist_path(tl_id))

                list_items.each do |l|
                     puts "((((#{l.title})))))"
                    expect(page).to have_content(l.title)
                    puts "((((", l.title
                    expect(page).to have_content(l.due_date)
                    expect(page).to have_content(l.description)
                end
            end
        end

        context "rq05d" do  

            scenario "TodoItem endpoint is accessible (show and destroy) through TodoList" do 
                tl_id = Todolist.all.sample.id
                list_items = Todolist.find(tl_id).todoitems
                # Confirm links in list page are nested and that the
                # show page results in expected method behavior
                list_items.each do |l|
                    visit(todolist_path(tl_id))
                    expect(page).to have_link('Show', :href => "#{todolist_todoitem_path(tl_id, l.id)}")
                    expect(page).to have_link('Destroy', :href => "#{todolist_todoitem_path(tl_id, l.id)}")
                end
            end

        end

        context "rq05e" do 

            scenario "TodoList page has new TodoItem link with specified URI and method" do 
                tl_id = Todolist.all.sample.id
                expect(:get => new_todolist_todoitem_path(tl_id)).to route_to(:controller => "todoitems", :action => "new", :todolist_id => "#{tl_id}")
                list_items = Todolist.find(tl_id).todoitems
                visit(todolist_path(tl_id))
                expect(page).to have_link('New Todo Item', :href => "#{new_todolist_todoitem_path(tl_id)}")
            end
        end 
    end

    context "rq07" do        
    
        before :all do    
            Todoitem.destroy_all
            Todolist.destroy_all
            User.destroy_all
            load "#{Rails.root}/db/seeds.rb"  
        end

        subject(:user) {
            User.find_by(:username=>"jim").authenticate("abc123")
        }

        context "rq07a" do
            scenario "Links navigate from TodoList-TodoItem summary page to Item show page" do
                tl_id = Todolist.all.sample.id
                list_item = Todolist.find(tl_id).todoitems.sample
                li_id = list_item.id
                # Confirm links in list page are nested and that the
                # show page results in expected method behavior
                visit(todolist_path(tl_id))
                expect(page).to have_link('Show', :href => "#{todolist_todoitem_path(tl_id, li_id)}")
                click_link('Show', :href => "#{todolist_todoitem_path(tl_id, li_id)}")
                expect(page).to have_content(list_item.title)
                expect(page).to have_content(list_item.due_date)
                expect(page).to have_content(list_item.description)
                expect(page).to have_content(list_item.completed)
            end

            scenario "Links navigate from item display back to TodoList-TodoItem summary page" do
                testList = Todolist.all.sample
                tl_id = testList.id
                list_item = Todolist.find(tl_id).todoitems.sample
                li_id = list_item.id
                # Confirm links in list page are nested and that the
                # show page results in expected method behavior
                visit(todolist_todoitem_path(tl_id, li_id))
                expect(page).to have_link('Back', :href => "#{todolist_path(tl_id)}")
                click_link('Back', :href => "#{todolist_path(tl_id)}");
                expect(page).to have_content(testList.list_name)
                expect(page).to have_content(testList.list_due_date)
            end

            scenario "Link navigates from TodoList-TodoItem summary page to Item destroy" do
                TodoitemsController.skip_before_action :ensure_login
                TodoitemsController.skip_before_action :verify_authenticity_token
                tl_id = Todolist.where(:user_id=>user.id).sample.id
                list_items = Todolist.find(tl_id).todoitems
                li_id = list_items.sample.id
                # replace with navigation here
                visit(todolist_path(tl_id))
                expect(page).to have_link('Destroy', :href => "#{todolist_todoitem_path(tl_id, li_id)}")
                click_link('Destroy', :href => "#{todolist_todoitem_path(tl_id, li_id)}");               
                expect(Todoitem.find_by(:id => li_id)).to be_nil
            end
        end

        context "rq07c" do
            scenario "Link navigates from TodoItem display page to Item edit page and updates item" do
                tl_id = Todolist.all.sample.id
                list_item = Todolist.find(tl_id).todoitems.sample
                li_id = list_item.id
                # Confirm links in list page are nested and that the
                # show page results in expected method behavior
                visit(todolist_todoitem_path(tl_id, li_id))
                expect(page).to have_link('Edit', :href => "#{edit_todolist_todoitem_path(tl_id, li_id)}")
                click_link('Edit', :href => "#{edit_todolist_todoitem_path(tl_id, li_id)}");
                expect(page).to have_content("Editing Todo Item")
                expect(find_field('todoitem[title]').value).to eq(list_item.title)
                expect(find_field('todoitem[description]').value).to eq(list_item.description)
                expect(page).to have_button("Update Todoitem")
                uString = "Updated value of #{Random.new.rand(10000)}"
                fill_in "todoitem[description]", with: uString
                click_button("Update Todoitem")
                expect(URI.parse(page.current_url).path).to eq("#{todolist_path(tl_id)}")
                expect(Todoitem.find_by(:id => li_id).description).to eq(uString)
            end

            scenario "Can navigate from TodoItem edit to show via Show link" do
                testList = Todolist.all.sample
                tl_id = testList.id
                list_item = Todolist.find(tl_id).todoitems.sample
                li_id = list_item.id
                # Confirm links in list page are nested and that the
                # show page results in expected method behavior
                visit(edit_todolist_todoitem_path(tl_id, li_id))
                expect(page).to have_link('Show', :href => "#{todolist_todoitem_path(tl_id, li_id)}")
                click_link('Show', :href => "#{todolist_todoitem_path(tl_id, li_id)}");
                expect(page).to have_content(list_item.title)
                expect(page).to have_content(list_item.description)
                expect(page).to have_content(list_item.due_date)
                expect(page).to have_content(list_item.completed)
            end

            scenario "Can navigate from TodoItem edit to home page with back link" do
                testList = Todolist.all.sample
                tl_id = testList.id
                list_item = Todolist.find(tl_id).todoitems.sample
                li_id = list_item.id
                # Confirm links in list page are nested and that the
                # show page results in expected method behavior
                visit(edit_todolist_todoitem_path(tl_id, li_id))
                expect(page).to have_link('Back', :href => "#{todolist_path(tl_id)}")
                click_link('Back', :href => "#{todolist_path(tl_id)}");
                expect(page).to have_content(testList.list_name)
                expect(page).to have_content(testList.list_due_date)
            end            
        end

        context "rq07d" do
            let(:testlist) { Todolist.all.sample }
            let(:tl_id) { testlist.id }
            let(:listitem) { Todolist.find(tl_id).todoitems.sample }
            let(:li_id) { listitem.id }

            scenario "Navigation link from list item view to new item form" do
                visit(todolist_path(tl_id, li_id))
                expect(page).to have_link('New Todo Item', :href => "#{new_todolist_todoitem_path(tl_id)}")
                click_link('New Todo Item', :href => "#{new_todolist_todoitem_path(tl_id)}")
                expect(URI.parse(page.current_url).path).to eq("#{new_todolist_todoitem_path(tl_id)}")
                expect(page).to have_content("New Todo Item")
            end

            scenario "New item form create adds new item and navigates to list item view" do 
                # confirm that route is correct
                expect(:post => todolist_todoitems_path(tl_id)).to route_to(:controller => "todoitems", :action => "create", :todolist_id => "#{tl_id}")
                visit(new_todolist_todoitem_path(tl_id))
                item = Todoitem.new(title:'Random', description:'Random entry', completed:false, due_date:Date.today)
                select item.due_date.year, from: 'todoitem[due_date(1i)]'
                select item.due_date.strftime("%B"), from: 'todoitem[due_date(2i)]'
                select item.due_date.day, from: 'todoitem[due_date(3i)]'
                fill_in 'todoitem[title]', with: item.title
                fill_in 'todoitem[description]', with: item.description
                click_button 'Create Todoitem'
                new_task = Todoitem.find_by! title: 'Random'
                # puts "******", new_task
                # puts "?????", item
                expect(new_task.description).to eq(item.description)
                expect(page).to have_content "Todo item was successfully created."
            end

            scenario "Back from new item form returns to list item view" do
                visit(new_todolist_todoitem_path(tl_id))
                expect(page).to have_link('Back', :href => "#{todolist_path(tl_id)}")
                click_link('Back', :href => "#{todolist_path(tl_id)}")
                expect(page).to have_content(testlist.list_name)
                expect(page).to have_content(testlist.list_due_date)
            end
        end

        context "rq07e" do
            let(:testList) { Todolist.all.sample }
            let(:tl_id) { testList.id }
            let(:listItem) { Todolist.find(tl_id).todoitems.sample }
            let(:li_id) { listItem.id }

            scenario "Completed field will be present in edit form" do
                # Go to edit page and check that completed field is present
                visit(edit_todolist_todoitem_path(tl_id, li_id))
                expect(page.has_field?('todoitem[completed]')).to be true
            end

            scenario "Completed field will not be present in new form" do
                visit(new_todolist_todoitem_path(tl_id))
                expect(page.has_field?('todo_item[completed]')).to be false
            end
        end

    end   
 end
