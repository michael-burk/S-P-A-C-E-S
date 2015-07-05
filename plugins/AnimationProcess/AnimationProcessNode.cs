#region usings
using System;
using System.ComponentModel.Composition;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	//last action hero
	public class ProcessAction
	{
		public ProcessAction(string name, double duration)
		{
			Name = name;
			Duration = duration;
		}
		
		public string Name { get; set; }
		public double Duration { get; set; }
		
		public double Progress
		{
			get;
			private set;
		}
		
		double FStartTime;
		bool FIsRunning;
		public void Start(double time)
		{
			FIsRunning = Duration > 0;
			FStartTime = time;
			FirstFrame = true;
			Progress = 0;
		}
		
		public void Reset()
		{
			Progress = 0;
			FIsRunning = false;
			LastFrame = false;
			FirstFrame = false;
		}
		
		public void Update(double time)
		{
			if(FIsRunning)
			{
				Progress = VMath.Clamp((time - FStartTime)/Duration, 0, 1);
				FirstFrame = Progress == 0;
				LastFrame = Progress == 1;
				
				if(LastFrame)
				{
					FIsRunning = false;
				}
			}
			else
			{
				FirstFrame = false;
				LastFrame = false;
			}
		}
		
		public bool FirstFrame
		{
			get;
			private set;
		}
		
		public bool LastFrame
		{
			get;
			private set;
		}
	}
	
	public class ActionChain
	{
		List<ProcessAction> FActions = new List<ProcessAction>();
		ProcessAction FIdleAction;
		IHDEHost FHost;
		
		public ActionChain()
		{
			FIdleAction = new ProcessAction("_Idle_", 0);
		}
		
		//modify list
		public void AddAction(string name, double duration)
		{
			FActions.Add(new ProcessAction(name, duration));
		}
		
		public void Clear()
		{
			FActions.Clear();
		}
		
		public ProcessAction this[int i]
		{
			get
			{
				return FActions[i];
			}
		}
		
		//do process
		bool FIsRunning;
		int FCurrentAction;
		double FStartTime;
		
		public bool Loop
		{
			get; set;
		}
		
		public bool Pause
		{
			get; set;
		}
		
		private double FTime;
		private double FLastTime;
		public double Time
		{
			get;
			private set;
		}
		
		public void UpdateTime()
		{
			var time = FHost.GetCurrentTime();
			FTime += Pause ? 0 : time - FLastTime;
			FLastTime = time;
		}
		
		public ProcessAction CurrentAction
		{
			get
			{
				return FIsRunning || Loop ? FActions[FCurrentAction] : FIdleAction;
			}
		}
		
		public void Start()
		{
			End = false;
			if(FIsRunning) return;
			
			FIsRunning = true;
			FStartTime = FTime;
			FCurrentAction = 0;
			FActions[0].Start(FTime);
		}
		
		bool FNewAction;
		
		public void Update()
		{
			
			if(FEnd)
			{
				LastFrame();
				FEnd = false;
			}
			else if(FIsRunning)
			{
				if(FNewAction)
				{
					FActions[Math.Max(FCurrentAction-1, 0)].Reset();
					FNewAction = false;
				}
					
				var a = FActions[FCurrentAction];
				
				a.Update(FTime);
				
				if(a.LastFrame)
				{
					FCurrentAction++;
					FNewAction = true;

					if(FCurrentAction == FActions.Count)
					{
						FCurrentAction = 0;
						FEnd = true;
						FIsRunning = false;
					}
					else
					{
						FActions[FCurrentAction].Start(FTime);
					}
				}
			}
		}
		
		bool FEnd;
		public bool End
		{
			get
			{
				return FEnd && !Loop;
			}
			private set
			{
				FEnd = value;
			}
		}
		
		public void Next()
		{
			FActions[FCurrentAction].Reset();
			FCurrentAction++;
			FCurrentAction %= FActions.Count;
			FActions[FCurrentAction].Start(FTime);
		}
		
		public void Back()
		{
			FActions[FCurrentAction].Reset();
			if(FCurrentAction == 0) FCurrentAction = FActions.Count -1;
			else FCurrentAction = Math.Max(0, FCurrentAction - 1);
			FActions[FCurrentAction].Start(FTime);
		}
		
		private void LastFrame()
		{
			FNewAction = false;
			for(int i=0; i<FActions.Count; i++)
			{
				FActions[i].Reset();
			}
			if(Loop) Start();
		}
				
		public void Reset()
		{
			End = !Loop;
			FIsRunning = false;
			LastFrame();
		}
		
		public void SetHost(IHDEHost host)
		{
			FHost = host;
		}
		
	}
	
	#region PluginInfo
	[PluginInfo(Name = "Process", Category = "Animation", 
	Help = "Plays a list of actions back",
	Tags = "logic, timeline, control, automata",
	Author = "tonfilm",
	AutoEvaluate = true)]
	#endregion PluginInfo
	public class C_AnimationProcessNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Start Process", IsBang = true, IsSingle = true)]
		ISpread<bool> FStartIn;
		
		[Input("Action Name")]
		IDiffSpread<string> FActionNameIn;
		
		[Input("Time", DefaultValue = 1)]
		IDiffSpread<double> FTimeIn;
		
		[Input("Next", IsBang = true, IsSingle = true)]
		ISpread<bool> FNextIn;
		
		[Input("Back", IsBang = true, IsSingle = true)]
		ISpread<bool> FBackIn;
		
		[Input("Pause", IsSingle = true)]
		ISpread<bool> FPauseIn;
		
		[Input("Reset", IsBang = true, IsSingle = true)]
		ISpread<bool> FResetIn;
		
		[Input("Loop", IsSingle = true)]
		ISpread<bool> FLoopIn;
		
		[Input("Idle Action Name", DefaultString = "_Idle_", Visibility = PinVisibility.OnlyInspector)]
		ISpread<string> FIdleActionNameIn;
		
		[Output("Current Action")]
		ISpread<string> FCurrentActionOut;
		
		[Output("In Action")]
		ISpread<bool> FInActionOut;
		
		[Output("Action First Frame", IsBang = true)]
		ISpread<bool> FActionFirstFrameOut;
		
		[Output("Action Last Frame", IsBang = true)]
		ISpread<bool> FActionLastFrameOut;
				
		[Output("Action Progress")]
		ISpread<double> FActionProgressOut;
		
		[Output("Process End", IsBang = true)]
		ISpread<bool> FProgressEndOut;

		[Import]
		ILogger FLogger;
		
		[Import]
		IHDEHost FHost;
		
		ActionChain FActionChain = new ActionChain();
		int FLastSpreadMax = 0;
		
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FInActionOut.SliceCount = SpreadMax;
			FActionFirstFrameOut.SliceCount = SpreadMax;
			FActionLastFrameOut.SliceCount = SpreadMax;
			FActionProgressOut.SliceCount = SpreadMax;
			
			var spreadCountChanged = SpreadMax != FLastSpreadMax;
			
			if(spreadCountChanged || FActionNameIn.IsChanged)
			{
				FActionChain.Clear();
				FActionChain.SetHost(FHost);
				for(int i=0; i<SpreadMax; i++)
				{
					FActionChain.AddAction(FActionNameIn[i], FTimeIn[i]);
				}
			}
			else if (FTimeIn.IsChanged)
			{
				for(int i=0; i<SpreadMax; i++)
				{
					FActionChain[i].Duration = FTimeIn[i];
				}
			}
			
			FActionChain.UpdateTime();
			
			if(FResetIn[0]) FActionChain.Reset();
			
			FActionChain.Loop = FLoopIn[0];
			FActionChain.Pause = FPauseIn[0];
			
			if(FNextIn[0]) FActionChain.Next();
			if(FBackIn[0]) FActionChain.Back();
			
			if(FStartIn[0])
			{
				FActionChain.Reset();
				FActionChain.Start();
			}
			
			FActionChain.Update();
			
			FCurrentActionOut[0] = FActionChain.CurrentAction.Name;
			
			for(int i=0; i<SpreadMax; i++)
			{
				var action = FActionChain[i];
				
				FInActionOut[i] = action == FActionChain.CurrentAction;
				FActionProgressOut[i] = action.Progress;
				FActionFirstFrameOut[i] = action.FirstFrame;
				FActionLastFrameOut[i] = action.LastFrame;
			}
			
			FProgressEndOut[0] = FActionChain.End;

			FLastSpreadMax = SpreadMax;
			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
}
