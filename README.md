# ICCONTEST2014_preliminary
這次的題目比較特殊，可以理解成要分別做以下的STI及DAC電路，再分別由TestBench來進行檢查，這邊我們先講當初實作時時序控制的部分，由於本題沒有對Simulation Time來進行一些要求，並且最後沒有被寫入的記憶體要強制寫0這件事情，所以在我的狀態機當中從一開始進入IDLE狀態以後，隨即馬上就進入CLEAR狀態，目的就是先將所有記憶體都先進行歸零的動作。

接著講在CLEAR狀態當中可能會遇到的問題，本題採用的寫入方式非正準位觸發，本題採用的是正緣觸發的方式，所以我利用 CLEAR 及 CLEAR2訊號交錯的技巧來製造正緣信號，並且在記憶體徹底清零後就跳離這個狀態。

## Timing / Area / Grade

| Timing | Cell Area | Grade |
| -------- | -------- | -------- |
| 10ns     | 6302     | Class A     |

最後出來的成績如上，以下我們進行兩塊電路的簡易說明。

## 1.序列傳輸介面處理電路(Serial Transmitter Interface, STI)
在這塊電路當中其實只是簡單的組合邏輯，首先接收資料後經由組合邏輯的運算處理排列成我們要的串列訊號，之後利用So_data這條訊號線來依序進行輸出。

## 2.資料排列控制電路(Data Arrange Controller, DAC)
DAC的部分則是接收So_data發送出來的訊號，將這些訊號分配到要寫入的記憶體位址，並且因為我們最開始就清零了，其實可以不用去理會pi_end這條輸入訊號線(原因在於STI的部份我們就已經判斷完成是否會繼續輸出串列資料)

