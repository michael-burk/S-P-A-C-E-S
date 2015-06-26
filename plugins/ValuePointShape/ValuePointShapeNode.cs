#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
using System.Collections.Generic;

#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "PointShape", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValuePointShapeNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input", DefaultValue = 1.0)]
		public ISpread<double> Input;

		
		[Input("BinSize", DefaultValue = 1)]
		public ISpread<int> Size;
		
		[Input("Steps", DefaultValue = 1)]
		public ISpread<int> Steps;

		[Output("Output")]
		public ISpread<double> FOutput;

		[Import()]
		public ILogger FLogger;
		#endregion fields & pins
		
		
		List<double> Points = new List<double>();
		
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = SpreadMax;
			
			int sliceCounter = 0;
			
			for (int j = 0; j < Size.SliceCount; j++){	
				
				for (int i = 0; i < Size[j]; i ++){
					
					FOutput[sliceCounter] = Input[sliceCounter];
					FOutput[sliceCounter+1] = Input[sliceCounter+1];
					
					
					sliceCounter +=2;
					
				}
				
			}
			
			for(int m = 0; m < Points.Count; m++){
					
					
					
			}
				

			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
}
