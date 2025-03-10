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
  * เมื่อผู้เล่นคนแรกเข้ามาจะ setstartTime
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

#### เมื่อผู้เล่นคนแรกเข้ามาแล้วไม่มีผู้เล่นอีกคนเข้ามา (จะอยู่ใน function checkTimeout())
  * จะกำหนดไว้ว่าจำนวนผุ้เล่นต้องเป็น 1 เท่านั้นจึงจะใช้งาน function ได้
  * เมื่อผู้เล่นคนที่เข้ามาสามารถกดใช้งาน function เวลาผ่านไปแล้วมากกว่า 1 นาที่(เวลาเริ่มต้นมาจากตอนที่เพิ่มผู้เล่นคนแรก) ผู้เล่นจะได้เงินที่ลงขันมาคืน
  * จะทำการรีเซ็ตเกมกลับไปให้เล่นได้อีกครั้ง
    ![image](https://github.com/user-attachments/assets/f77511dd-481c-488f-8080-77f4d4d2d8f0)

#### การซ่อน choice และ commit (จะอยู่ใน function addPlayer(), getHash(bytes32 data) และ input(bytes32 choice))
  * ผู้เล่นจะต้องทำการนำ choice ไปรวมกับค่า random ก่อน [แปลงค่าที่นี่]([LinktoGo](https://colab.research.google.com/drive/1PA-QhkX3qa1iSn8qunInzX6E8xtRBIjG))
  * นำ data ที่ได้มาเข้า function hash
    * โดย function hash จะทำการไปเรียกใช้ function getHash(data) ที่อยู่ในไฟล์ CommitReveal.sol และจะ return ค่าที่ hash แล้วกลับมาให้ผู้ใช้
      
  * นำค่าที่ได้จาก hash มาใส่เป็น input ใน function input(bytes32 choice)
    * โดย fuction input 
