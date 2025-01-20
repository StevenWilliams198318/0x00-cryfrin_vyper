# pragma version ^0.4.0
"""
@license MIT
@title Buy Me A Coffee!
@author Steven Williams!
@notice This contract is for creating a sample funding contract
"""

interface AggregatorV3Interface:
    def decimals() -> uint8: view
    def description() -> String[1000]: view
    def version() -> uint256: view
    def latestAnswer() -> int256: view

# constants & immutables
MINIMUM_USD: public(constant(uint256)) = as_wei_value(1600000000000000, "wei")  # Minimum funding amount in ETH (converted to USD)
PRICE_FEED: public(immutable(AggregatorV3Interface))             # Chainlink price feed contract for ETH/USD
PRECISION: constant(uint256) = 1 * (10 ** 18)                    # Used to handle fixed-point arithmetic in Solidity

# storage
current_owner: public(address)
funders: public(DynArray[address, 1000])                         # Array to store addresses of funders
funder_to_amount_funded: public(HashMap[address, uint256])       # Mapping from funder address to the amount funded
number_of_funders: public(uint256)                               # 0x694AA1769357215DE4FAC081bf1f309aDC325306

# constructor: initializing constants & immutables
@deploy
def __init__(price_feed: address):
    PRICE_FEED = AggregatorV3Interface(price_feed)               # Set the price feed address
    self.current_owner = msg.sender                              # Set the owner as the deployer's address


@internal
@view
def _get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    """
    Internal function to calculate the USD value of a given amount of ETH
    """
    price: int256 = staticcall PRICE_FEED.latestAnswer()         # Get the latest ETH/USD price
    eth_price: uint256 = (convert(price, uint256)) * (10**10) 
    eth_amount_in_usd: uint256 = (eth_price * eth_amount) // PRECISION    # Calculate ETH amount in USD
    return eth_amount_in_usd                                    # Return the USD equivalent of the ETH amount

@external
@view
def get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    """
    External function to get the USD value of a given ETH amount
    """
    return self._get_eth_to_usd_rate(eth_amount)

@external
@payable
def fund():
    """
    External function allowing users to fund ETH to this contract
    """
    self._fund()

@internal
@payable
def _fund():
    """
    Internal function to handle funding logic, including minimum USD check
    """
    usd_value_of_eth: uint256 = self._get_eth_to_usd_rate(msg.value)  # Convert ETH sent to USD
    assert usd_value_of_eth >= MINIMUM_USD, "Need to spend more ETH!"  # Ensure funding meets minimum
    self.funders.append(msg.sender)                                  # Add funder's address to the array
    self.funder_to_amount_funded[msg.sender] += msg.value            # Track the amount funded by the sender

@external
def withdraw():
    """
    External function to allow the owner to withdraw all funds
    """
    assert msg.sender == self.current_owner, "Only owner can withdraw" # Ensure only the owner can withdraw
    raw_call(self.current_owner, b"", value=self.balance)                         # Send contract balance to the owner
    for i: address in self.funders:                                  # Iterate through funders
        self.funder_to_amount_funded[i] = 0                          # Reset funding amounts
    self.funders = []                                                # Clear the funders array

@external
@view
def get_total_funds() -> uint256:
    """Return total funds in the contract by looping through funders
    """
    total_funded: uint256 = 0
    for funder: address in self.funders:
        total_funded += self.funder_to_amount_funded[funder] # To get value from HashMap[] use a key - address(funder)        
    return total_funded

@external
def change_ownership(new_owner: address):
    """
    Allowing current owner to transfer ownership to a new address
    new_owner: The address of the new owner
    """
    assert msg.sender == self.current_owner, " Only Owner can change ownership"
    assert new_owner != empty(address), "new owner cannot be an empty address"
    self.current_owner = new_owner

@external
@payable
def __default__():
    """
    Fallback function to allow direct ETH transfers to the contract
    """
    self._fund()

