เกมเป่ายิงชุบที่มีทั้งหมด 5 ตัวเลือก คือ rock paper scissors spock lizard
โดยการชนะจะเป็นดังภาพ
![image](https://github.com/user-attachments/assets/f99f808d-aeac-4752-bea5-70824719df5a)

# อธิบาย code และการทำงานของ RPS
#### การเพิ่มผู้เล่น (จะอยู่ใน function addPlayer())
  * ผู้เล่นจะต้องมีแค่ 2 คน
  * ผู้เล่นที่สามารถเล่นได้จะมีแค่ 4 account ดังนี้
       1. 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
       2. 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
       3. 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
       4. 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
  * ผู้เล่นทั้งสองต้องไม่ใช่ account เดียวกัน
  * ผู้เล่นจะต้องลงขันกันคนละ 1 ETH
  * เมื่อผู้เล่นคนแรกเข้ามาจะ setStartTime เพื่อใช้เมื่อมีผู้เล่นเข้ามาเพียงคนเดียวแล้วเงินถูกล็อกไว้
  * เมื่อผู้เล่นเข้ามาครบ 2 คนแล้วก็จะ setstartTime ใหม่
```solidity
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
```

#### ให้ผู้เล่นคืนเงินได้ เมื่อผู้เล่นคนแรกเข้ามาแล้วไม่มีผู้เล่นอีกคนเข้ามา (จะอยู่ใน function checkTimeout())
  * จะกำหนดไว้ว่าจำนวนผู้เล่นต้องเป็น 1 เท่านั้นจึงจะใช้งาน function ได้
  * เมื่อผู้เล่นคนที่เข้ามาสามารถกดใช้งาน function เวลาผ่านไปแล้วมากกว่า 1 นาที่(เวลาเริ่มต้นมาจากตอนที่เพิ่มผู้เล่นคนแรก) ผู้เล่นจะได้เงินที่ลงขันมาคืน
  * จะทำการรีเซ็ตเกมกลับไปให้เล่นได้อีกครั้ง
```solidity
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
```

#### การซ่อน choice และ commit (จะอยู่ใน function getHash(bytes32 data) และ input(bytes32 choice))
  * ผู้เล่นจะต้องทำการนำ choice ไปรวมกับค่า random ก่อน [แปลงค่าที่นี่]([LinktoGo](https://colab.research.google.com/drive/1PA-QhkX3qa1iSn8qunInzX6E8xtRBIjG))
  * นำ data ที่ได้มาเข้า function hash
    * โดย function hash จะทำการไปเรียกใช้ function getHash(data) ที่อยู่ในไฟล์ CommitReveal.sol และจะ return ค่าที่ hash แล้วกลับมาให้ผู้ใช้
      ```solidity
      function getHash(bytes32 data) public view returns(bytes32){
        return commitReveal.getHash(data);
      }
      ```
  * นำค่าที่ได้จาก hash มาใส่เป็น input ใน function input(bytes32 choice)
    * โดย fuction input จะใช้ได้สำเร็จเมื่อมีผู้เล่นครบ 2 คน
    * เมื่อผู้เล่น input ค่ามาแล้วจะทำการ commit choice ที่ผู้เล่นได้ส่งมาซึ่งทำการ hash มาแล้ว
    * กำหนดให้ player คนนี้ยังไม่ได้ทำการ reveal เอาไว้ก่อน
    * เมื่อผู้เล่นคนแรกใส่ค่าจะ setStartTime เพื่อใช้เมื่อผู้เล่นอีกคนไม่ยอม input เข้ามาแล้วเงินถูกล็อกไว้
    ```solidity
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
    ```
#### ให้ผู้เล่นคืนเงินได้ เมื่อผู้เล่นคนนึง input มาแล้วแต่อีกคนไม่ยอม input เข้ามา (จะอยู่ใน function checkTime_play())
 * จะใช้ได้เมื่อ มีผู้เล่น 2 คนแล้ว แต่มีคน input มาแค่ 1
 * เมื่อกดใช้งาน function เมื่อเวลาผ่านไปแล้วมากกว่า 1 นาที่(เวลาเริ่มต้นมาจากตอนที่ผู้เล่นได้ทำการใส่ input เข้ามาคนแรก) ผู้เล่นจะได้เงินที่ลงขันทั้งหมดไป
 * โดยจะทำการเช็คว่าผู้เล่นคนไหนที่เป็นคน input
   ``` solidity
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
   ```
#### การ reveal และนำ choice มาตัดสินรวมถึงการเริ่มเล่นใหม่ได้ (จะอยู่ใน function reveal(bytes32 revealHash), _checkWinnerAndPay(), _play_again())
 * ผู้เล่นนำ data(ค่าที่ได้ก่อนนำไป hash) มาใส่ function reveal
  * โดย function reveal จะเรียกใช้ function reveal(revealHash) ที่อยู่ในไฟล์ CommitReveal.sol
  * เก็บค่า reveal ของแต่ละ player ไว้ใน player_reveal
  * กำหนดให้ player_is_reveal ของ player นั้นเป็น true
  * เมื่อ player ทำการ reveal ครบทั้งสองคนแล้วจะทำการเรียก function _checkWinnerAndPay() เพื่อตัดสิน
    ``` solidity
      function reveal(bytes32 revealHash) public {
        commitReveal.reveal(revealHash);
        player_reveal[msg.sender]=revealHash;
        player_is_reveal[msg.sender]=true;

        if (player_is_reveal[players[0]] && player_is_reveal[players[1]]) {
            _checkWinnerAndPay();
        }
    }
    ```
 * ในการตัดสินจะเช็คก่อนว่า player ทำการ reveal ครบทั้งสองคนหรือยัง
 * จะหาว่าแต่ละ player เลือก choice อะไรจากการที่นำค่า reveal มาและกับ 0*ff เพื่อเอาแค่ 2 ตัวท้าย (คือค่า choice) และแปลงเป็น unit
 * จะทำการตัดสินว่าใครแพ้ ชนะ จาก (choice+1)%5 หรือ (choice+3)%5 เพราะ 1 choice สามารถชนะ และแพ้ได้ 2 อย่าง
   ![image](https://github.com/user-attachments/assets/30f670c6-b838-47cb-b6d9-73c714fdedfd)
 * เมื่อตัดสินแล้วจะเรียกใช้ function _play_again()
``` solidity
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
```
 * fuction _play_again() จะทำการ reset ทุกอย่างให้กลับไปเหมือนเริ่มต้น
``` solidity
 function _play_again() private {
        require(numPlayer == 2 && !player_not_played[msg.sender]);
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        players.pop();
        players.pop();
    }
```

