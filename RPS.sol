
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS {
    uint public numPlayer = 0;
    uint public reward = 0;
    bool canplay_or_not = false;
    mapping (address => bytes32) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - spock, 4 - lizard
    mapping (address => bytes32) player_reveal;
    mapping(address => bool) public player_not_played;
    mapping(address => bool) public player_is_reveal;
    address[] public players;
    address[] public players_can =[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
                                   0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB];
    
    uint public numInput = 0;
    TimeUnit timeUnit = new TimeUnit();
    bool public TimeOut = false;
    bool public Timeout_for_play = false;
    CommitReveal commitReveal = new CommitReveal();

    function addPlayer() public payable {
        require(numPlayer < 2);
        for (uint i = 0; i < players_can.length; i++)
        {
            if (msg.sender == players_can[i]){
                canplay_or_not = true;
                break;
            }
            else 
                canplay_or_not = false;
        }

        if(numPlayer==0){
            timeUnit.setStartTime();
        }
        else {
            require(msg.sender != players[0] && canplay_or_not == true); //ให้ player เป็นคนละ account
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true; //msg.sender คือ address ของ account
        players.push(msg.sender); //เพิ่มสมาชิกเข้าไปใน array
        numPlayer++;
        if(numPlayer == 2){
            timeUnit.setStartTime();
        }
        //ถ้าได้ครบ 2 คนให้ reset start time
    }
    
    function checkTimeout() public{
        require(numPlayer==1);
        if(timeUnit.elapsedMinutes()>1){
            TimeOut = true;
            address payable account0 = payable(players[0]);
            account0.transfer(reward);
            numPlayer = 0;
            reward = 0;
            numInput = 0;
        }
    }

    function input(bytes32 choice) public  { //จะเปลี่ยนเป็น btyes32 แทนแล้วเพราะเราจะเปลี่ยนให้มองไม่รู้ว่าเลือกอะไร
        require(numPlayer == 2);
        require(player_not_played[msg.sender]); //มันจะมีแค่ 2 address ที่ได้เรียก map จัวนี้มาก่อนซึ่งก็คือ 2 ตัวที่เราทำก่อนหน้านี้
        // require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
        player_choice[msg.sender] = choice; //เอาไป map กับ choice ที่เขาเลือก
        player_not_played[msg.sender] = false; // เขาเลือกไปแล้วเราก็ให้ false
        commitReveal.commit(choice);
        player_is_reveal[msg.sender]=false;
        numInput++;
        if(numInput == 1 ){
            timeUnit.setStartTime();
        }
    }

    function _checkWinnerAndPay() private {
        //player0 ต้อง call reveal
        //player1 ต้อง call reveal
        //check ว่า reveal มันสำเร็จหมดไหม
        require(player_is_reveal[players[0]] && player_is_reveal[players[1]], "Both players must reveal their choices");
        uint p0Choice = uint(uint256(player_reveal[players[0]]) & 0xff);
        uint p1Choice = uint(uint256(player_reveal[players[1]]) & 0xff);

        //retrive player0 form input to reveal
        //retrive player1 form input to reveal

        address payable account0 = payable(players[0]); //ระบุให้ adress สามารถรับ eth ได้บางอันมันรับได้อยู่แล้วแต่เราทำเพื่อความแน่ใจ
        address payable account1 = payable(players[1]);
        if (p0Choice== p1Choice) {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to pay player[1]
            account1.transfer(reward);
            
        }
        _play_again();
    }

    //ต้องเพิ่มฟังก์ชันที่ไปเช็คปัญหาที่ว่าลงมา 2 คนแล้วแต่อีกคนไม่ออกอาาวุธ อาจจะให้ 1 ชั่วโมงผ่านไปแล้วจะบังคับจบเกม
    function checkTime_play() public {
        require(numPlayer == 2 && numInput==1);
        if(timeUnit.elapsedMinutes()>1){
            Timeout_for_play = true;
            if(!player_not_played[players[0]]){
                payable(players[0]).transfer(reward);
            }else 
                payable(players[1]).transfer(reward);
            _play_again();
        }
    }

    function getHash(bytes32 data) public view returns(bytes32){
        return commitReveal.getHash(data);
    }
    function reveal(bytes32 revealHash) public {
        commitReveal.reveal(revealHash);
        player_reveal[msg.sender]=revealHash;
        player_is_reveal[msg.sender]=true;
        
        if (player_is_reveal[players[0]] && player_is_reveal[players[1]]) {
            _checkWinnerAndPay();
    }
    }
    function _play_again() private {
        require(numPlayer == 2 && !player_not_played[msg.sender]);
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        players.pop();
        players.pop();
    }
}