Set Implicit Arguments.

Add LoadPath "../HAL".

Require Import Bool.
Require Import EqNat.

Require Import SchedThread.

Require Import DLClist.
Require Import ThreadTimer.
Require Import HardwareThread.
Require Import SuspendQueue.

Section ThreadStateSec.

  Inductive ThreadStateConstant : Set :=
  | RUNNING : ThreadStateConstant
  | SLEEPING : ThreadStateConstant
  | COUNTSLEEP : ThreadStateConstant
  | SUSPENDED : ThreadStateConstant
  | CREATING : ThreadStateConstant
  | EXITED : ThreadStateConstant
  | SLEEPSET : ThreadStateConstant.

  Record ThreadState := mkTS {
    sleeping : bool;
    countsleep : bool;
    suspended : bool;
    creating : bool;
    exited : bool
  }.

  Definition ThreadState_cstr := mkTS false false true false false.

  Definition check_state ts tsc :=
    match tsc with
      |RUNNING => negb (ts.(sleeping) || ts.(countsleep) 
                          || ts.(suspended) || ts.(creating) || ts.(exited))
      |SLEEPING => ts.(sleeping)
      |COUNTSLEEP => ts.(countsleep)
      |SUSPENDED => ts.(suspended)
      |CREATING => ts.(creating)
      |EXITED => ts.(exited)
      |SLEEPSET => ts.(sleeping) || ts.(countsleep)
    end.

  Definition check_state_eq ts tsc := 
    match tsc with
      |RUNNING => negb (ts.(sleeping) || ts.(countsleep) 
                          || ts.(suspended) || ts.(creating) || ts.(exited))
      |SLEEPING => ts.(sleeping) && (negb (ts.(countsleep) 
                                             || ts.(suspended) || ts.(creating) || ts.(exited)))
      |COUNTSLEEP => ts.(countsleep) && (negb (ts.(sleeping) 
                                                 || ts.(suspended) || ts.(creating) || ts.(exited)))
      |SUSPENDED => ts.(suspended) && (negb (ts.(sleeping) 
                                               || ts.(countsleep) || ts.(creating) || ts.(exited)))
      |CREATING => ts.(creating) && (negb (ts.(sleeping) 
                                             || ts.(countsleep) || ts.(suspended) || ts.(exited)))
      |EXITED => ts.(exited) && (negb (ts.(sleeping) 
                                         || ts.(countsleep) || ts.(suspended) || ts.(creating)))
      |SLEEPSET => (ts.(sleeping) || ts.(countsleep)) && (ts.(suspended) || ts.(creating) || ts.(exited))
    end.

  Definition alter_state ts tsc b := 
    match tsc with
      |RUNNING => match b with 
                    |true => mkTS false false false false false
                    |false => ts (*shouldn't be*)
                  end
      |SLEEPING => mkTS b ts.(countsleep) ts.(suspended) ts.(creating) ts.(exited)
      |COUNTSLEEP => mkTS ts.(sleeping) b ts.(suspended) ts.(creating) ts.(exited)
      |SUSPENDED => mkTS ts.(sleeping) ts.(countsleep) b ts.(creating) ts.(exited)
      |CREATING => mkTS ts.(sleeping) ts.(countsleep) ts.(suspended) b ts.(exited)
      |EXITED => mkTS ts.(sleeping) ts.(countsleep) ts.(suspended) ts.(creating) b
      |SLEEPSET => match b with 
                     |true => ts (*shouln't be*)
                     |false => mkTS false false ts.(suspended) ts.(creating) ts.(exited)
                   end
    end.

  Definition alter_state_eq tsc := 
    match tsc with
      |RUNNING => mkTS false false false false false 
      |SLEEPING => mkTS true false false false false
      |COUNTSLEEP => mkTS false true false false false
      |SUSPENDED => mkTS false false true false false
      |CREATING => mkTS false false false true false
      |EXITED => mkTS false false false false true
      |SLEEPSET => ThreadState_cstr  (*shouln't be*)
    end.

End ThreadStateSec.

Section ReasonSec.

  Inductive Reason : Set :=
  | NONE : Reason
  | WAIT : Reason
  | DELAY : Reason
  | TIMEOUT : Reason
  | BREAK : Reason
  | DESTRUCT : Reason
  | EXIT : Reason
  | DONE : Reason.

  Definition reason_eq r r' :=
    match r, r' with
      |NONE, NONE => true
      |WAIT, WAIT => true
      |DELAY, DELAY => true
      |TIMEOUT, TIMEOUT => true
      |BREAK, BREAK => true
      |DESTRUCT, DESTRUCT => true
      |EXIT, EXIT => true
      |DONE, DONE => true
      |_, _ => false
    end.

  Record SleepWakeup := mkSW {
    sleep_reason : Reason;
    wake_reason : Reason;
    suspend_count : nat;
    wakeup_count : nat
  }.

  Definition SleepWakeup_set_wake_reason sw wr :=
    mkSW NONE wr sw.(suspend_count) sw.(wakeup_count).

  Definition SleepWakeup_set_sleep_reason sw sr :=
    mkSW sr NONE sw.(suspend_count) sw.(wakeup_count).

  Definition SleepWakeup_set_suspend_count sw sc :=
    mkSW sw.(sleep_reason) sw.(wake_reason) sc sw.(wakeup_count).

  Definition SleepWakeup_set_wakeup_count sw wc :=
    mkSW sw.(sleep_reason) sw.(wake_reason) sw.(wakeup_count) wc.

End ReasonSec.

Record Thread := mkThread{

  unique_id : nat; 
  timer : ThreadTimer;
  state : ThreadState;
  wait_info : nat;
  sleepwakeup : SleepWakeup;

  (*Inherited from SchedThread_Implementation*)
  schedthread : SchedThread;
  hardware : HardwareThread
}.

(*---------------------------get & set fields-----------------------*)

Definition get_priority t := SchedThread.get_priority t.(schedthread).

Definition set_priority t n :=
  mkThread t.(unique_id) t.(timer) t.(state) t.(wait_info) t.(sleepwakeup)
    (SchedThread.set_priority t.(schedthread) n) t.(hardware).

Definition get_current_priority t := get_priority t.

Definition get_unique_id t := t.(unique_id).

Definition set_unique_id t tid := 
  mkThread tid t.(timer) t.(state) t.(wait_info) t.(sleepwakeup) t.(schedthread) t.(hardware).

Definition get_current_queue t := SchedThread.get_current_queue t.(schedthread). 

Definition set_current_queue t q := 
  mkThread t.(unique_id) t.(timer) t.(state) t.(wait_info) t.(sleepwakeup) 
     (SchedThread.set_current_queue t.(schedthread) q) t.(hardware).

Definition get_threadtimer t := t.(timer).

Definition set_threadtimer t tt := 
  mkThread t.(unique_id) tt t.(state) t.(wait_info) t.(sleepwakeup) t.(schedthread) t.(hardware).

Definition set_sleepwakeup t sw :=
  mkThread t.(unique_id) t.(timer) t.(state) t.(wait_info) sw t.(schedthread) t.(hardware).

Definition get_suspend_count t := t.(sleepwakeup).(suspend_count).

Definition set_suspend_count t n := 
  set_sleepwakeup t (SleepWakeup_set_suspend_count t.(sleepwakeup) n).

Definition get_wakeup_count t := t.(sleepwakeup).(wakeup_count).

Definition set_wakeup_count (t : Thread) n : Thread :=
  set_sleepwakeup t (SleepWakeup_set_wakeup_count t.(sleepwakeup) n).

Definition get_sleep_reason t := t.(sleepwakeup).(sleep_reason).

Definition set_sleep_reason t sr := 
  set_sleepwakeup t (SleepWakeup_set_sleep_reason t.(sleepwakeup) sr).

Definition get_wake_reason t := t.(sleepwakeup).(wake_reason).

Definition set_wake_reason t wr :=
  set_sleepwakeup t (SleepWakeup_set_wake_reason t.(sleepwakeup) wr).

Definition set_schedthread t ss := 
  mkThread t.(unique_id) t.(timer) t.(state) t.(wait_info) t.(sleepwakeup) ss t.(hardware).

Definition set_queue t sq := set_schedthread t (SchedThread.set_queue t.(schedthread) sq).

Definition timeslice_save t new_count := 
  set_schedthread t (SchedThread.timeslice_save t.(schedthread) new_count).

Definition get_timeslice_count t := SchedThread.get_timeslice_count t.(schedthread).

Definition get_state t := t.(state).

Definition set_state t s :=
  mkThread t.(unique_id) t.(timer) s t.(wait_info) t.(sleepwakeup) t.(schedthread) t.(hardware).

Definition thread_check_state t tsc := check_state (get_state t) tsc.

Definition thread_check_state_eq t tsc := check_state_eq (get_state t) tsc.

Definition thread_alter_state t tsc b := set_state t (alter_state (get_state t) tsc b). 

Definition thread_alter_state_eq t tsc := set_state t (alter_state_eq tsc).

Definition set_wait_info t wi := 
  mkThread t.(unique_id) t.(timer) t.(state) wi t.(sleepwakeup) t.(schedthread) t.(hardware).

Definition get_wait_info t := t.(wait_info).

Definition get_hardware_thread t := t.(hardware).

Definition set_hardware_thread t ht :=
  mkThread t.(unique_id) t.(timer) t.(state) t.(wait_info) t.(sleepwakeup) t.(schedthread) ht.

Definition get_stack_ptr t := HardwareThread.get_stack_ptr t.(hardware).

Definition set_stack_ptr t ptr := 
  set_hardware_thread t (HardwareThread.set_stack_ptr t.(hardware) ptr).

Definition push t n := 
  set_hardware_thread t (HardwareThread.push t.(hardware) n).

Definition pop (t : Thread) : Thread * nat.
destruct (HardwareThread.pop t.(hardware)) as [ht n].
exact (set_hardware_thread t ht, n).
Defined.

(*---------------------------get & set fields end-----------------------*)

Definition Thread_cstr tid aid cid p e_point e_data s_size s_base : Thread := 
  mkThread tid (ThreadTimer_cstr aid cid tid) ThreadState_cstr 
           0 (mkSW NONE NONE 1 0) (SchedThread_cstr p)
           (init_context (HardwareThread_cstr e_point e_data s_size s_base) tid).

(*reinitialize : defined in Kernel.v*)
Definition reinitialize_thread (t : Thread)(new_id : nat) : Thread :=
set_unique_id (set_wake_reason (set_sleep_reason (set_wakeup_count 
  (set_suspend_count (thread_alter_state_eq t SUSPENDED) 1) 0) NONE) NONE) new_id.

(*to_queue_head : defined in Kernel.v*)

(*wake : defined in Kernel.v*)

(*counted_wake : defined in Kernel.v*)

(*cancel_counted_wake : defined in Kernel.v*)

(*suspend : defined in Kernel.v*)

(*resume : defined in Kernel.v*)

(*release : defined in Kernel.v*)

(*kill : defined in Kernel.v*)

(*force_resume : defined in Kernel.v*)

(*delay : defined in Kernel.v*)

(*set_priority : defined in kernel.v*)

(*sleep : defined in Kernel.v*)

(*counted_sleep : defined in Kernel.v*)

(*counted_sleep_delay : defined in kernel.v*)

(*exit : defined in Kernel.v*)

(*self : defined in Kernel.v*)

(*set_timer : defined in kernel.v*)

(*clear_timer : defined in Kernel.v*)

Definition timeslice_reset t := 
  set_schedthread t (SchedThread.timeslice_reset t.(schedthread)).

(********************************************************)
(*The double linked cycled list of thread*)

Module Thread_Obj <: DNode.

  Definition Obj := Thread.

  Definition eq_Obj (x y : Thread) :=
    beq_nat x.(unique_id) y.(unique_id).

  Definition A := nat.
  
  Definition test_Obj t n := beq_nat t.(unique_id) n.  

End Thread_Obj.

Module TO := CList Thread_Obj.

Definition ThreadQueue := TO.CList Thread.

Definition ThreadQueue_cstr := @nil Thread.

Definition get_thread (q : ThreadQueue) (tid : nat) : option (nat*nat).
induction q as [ |t q' IHq']; [exact None| ].
  case_eq (beq_nat tid t.(unique_id)); intros h.
    exact (Some ((get_priority t), 0)).  
    destruct IHq' as [x| ]. 
      destruct x as [f s]. exact (Some (f, (S s))).
      exact None. 
Defined.

Definition get_thread_t (q : ThreadQueue) (tid : nat) : option Thread :=
  TO.get_Obj q tid.

Definition update_thread (q : ThreadQueue) (t : Thread) : ThreadQueue :=
  TO.update_Obj q t.

(*replace t with t', t and t' have different unique_id*)
Definition replace_thread (q : ThreadQueue) (t t' : Thread) : ThreadQueue :=
  TO.remove (TO.insert q t t') t.

Definition get_threadtimer_by_id (q : ThreadQueue) (ttid : nat) : option ThreadTimer.
induction q as [|t q' IHq'].
-exact None.
-destruct (beq_nat (get_timer_id (get_threadtimer t)) ttid).
  +exact (Some (get_threadtimer t)).
  +exact IHq'.
Defined.