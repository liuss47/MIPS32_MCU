## v1

### 1.五级流水线的初步构建
​    (1)完成了基本模块的搭建，包括PC,IF_IT,IT,IT_EXE,EXE,EXE_MEB,MEB,MEB_WB  
​    (2)完成了SOPC测试封装，进行了波形仿真
​    (3)完成了工艺综合

## v2

### 1.整体结构的调整
​    对五级流水结构进行修改，添加执行和访存阶段的数据回流，实现RAW冲突的修正   
### 2.指令集的扩充
​    (1)8条逻辑指令:and andi or ori xor xori nor lui  
​    (2)6条移位指令:sll sllv sra srav srl srlv  
​    (3)2条空白指令:nop,ssnop  
​    (4)其他指令: sync pref  

## v3