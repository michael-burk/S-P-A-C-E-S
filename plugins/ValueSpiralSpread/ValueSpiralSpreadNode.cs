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
	#region PluginInfo
	[PluginInfo(Name = "SpiralSpread", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValueSpiralSpreadNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input", DefaultValue = 1.0)]
		public ISpread<double> FInput;
		
			[Input("Width", IsSingle=true, DefaultValue = 6)]
			public ISpread<int> FWidth;
			
			[Input("Height", IsSingle=true, DefaultValue = 6)]
			public ISpread<int> FHeight;
			
			[Output("Output")]
			public ISpread<Vector2D> FOutput;
		
		[Import()]
		public ILogger FLogger;
		#endregion fields & pins
		
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			//			FOutput.SliceCount = SpreadMax;
			
			
			
			
			//			int x = 0;
			//			int y = 0;
			//			int[] delta = new int[] {0, -1};
			
			List<Vector2D> xy = new List<Vector2D>();
			xy.Add(new Vector2D(0,0));
			//			List<int> y = new List<int>();
			
			//			List<Vector2D> delta = new List<Vector2D>();
			
			Vector2D delta = new Vector2D(0, -1);
			
			//			delta.Add(new Vector2D(0, -1));
			//			delta.Add(-1);
			
			
			//        	int deltaX = 0;
			//			int deltaY = -1;
			
			
			int max = (int)Math.Pow(Math.Max(FWidth[0],FHeight[0]), 2);
			
			
			FLogger.Log(LogType.Debug, "max: " + max);
			
			FOutput.SliceCount = max;
			
			
			
			for (int i = max; i > 0; i--)
			{
				
				int x = (int)xy[xy.Count-1].x;	
				int y = (int)xy[xy.Count-1].y;
				
				if (x == y ||
				(x < 0 && x == -y) ||
				(x > 0 && x == 1 - y))
				{
					
					// change direction
					//	            delta = [-delta[1], delta[0]];
//					delta[0] = -delta[1];
//					delta[1] = delta[0];
					
					int tempx = (int)delta.x;
					
					delta.x = -delta.y;
					delta.y = tempx;
					
				}
				
				//				x += delta[0];
				//				y += delta[1];
				
//				x.Add((int)delta.x);
//				y.Add((int)delta.y);
				FLogger.Log(LogType.Debug, "add-------------");
				xy.Add(new Vector2D(delta.x, delta.y));
				FLogger.Log(LogType.Debug, "done-------------");
				
//				FLogger.Log(LogType.Debug, "xy: " + xy[i].x + "," + xy[i].y);
				
				//				FOutput[i] = delta;
				
				
				
			}
			
			FOutput.AssignFrom(xy);
			
			//FLogger.Log(LogType.Debug, "hi tty!");
		}
		
	}
	
}



