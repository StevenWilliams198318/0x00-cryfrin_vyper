# pragma version 0.4.0

"""
@license MIT
@title My favorite number!
@author Steven Williams!
@notice This contract showcases basic Vyper functionality:
    state variables, 
    structs,
    fixed size arrays,
    hash mappings.
@notice It stores a favorite number and acess it, along with keeping at list of people with their favorite numbers.
"""

struct Person:
    favorite_number: uint256 
    name: String[100]       # '100' is the limit of characters per name

my_favorite_number: uint256

# Static Array/List to store numbers and people
list_of_numbers: public(uint256[5])
list_of_people: public(Person[5])
list_of_people_index: uint256

# HashMap linking names to their favorite numbers
name_to_favorite_number: HashMap[String[100], uint256]

# Constructors initialize things at deployment of the contract.
# E.G: `my_favorite_number` to 7.
@deploy
def __init__():
    self.my_favorite_number = 7

# Stores a number to my_favorite_number based on arg: 'favorite_number: uint256'
@external
def store(favorite_number: uint256):
    self.my_favorite_number = favorite_number

# Returns current number from 'my_favorite_number'
@external
@view
def retrieve() -> uint256:
    return self.my_favorite_number

# Function create and stores a new person with their name & favorite number
@external
def add_person(name: String[100], favorite_number: uint256):                    # Receives new name and number                    
    new_person: Person = Person(favorite_number = favorite_number, name = name) # Create a new Person struct with the name and number
    self.list_of_people[self.list_of_people_index] = new_person                 # Then adds new person to the list of people
    self.list_of_numbers[self.list_of_people_index] = favorite_number           # Then adds the favorite number to the list of numbers
    self.list_of_people_index += 1                                              # Increment the index for the next person
    self.name_to_favorite_number[name] = favorite_number                        # Maps the person's name to their favorite number
