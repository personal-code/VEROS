Set Implicit Arguments.

Record Alarm := mkALM{
  
  unique_id : nat;
  trigger : nat;
  interval : nat;
  enable : bool

}.


(*DO : Alarm construct func, ignore counter alarm data*)


Definition AlarmList := list Alarm.

(*TODO : functions operating the list*)

