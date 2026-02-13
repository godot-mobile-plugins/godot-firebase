//
// © 2026-present https://github.com/firebase-team
//

package org.godotengine.plugin.firebase;

import android.app.Activity;
import android.util.Log;
import android.view.View;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.godotengine.godot.Godot;
import org.godotengine.godot.Dictionary;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;


public class FirebasePlugin extends GodotPlugin {
	public static final String CLASS_NAME = FirebasePlugin.class.getSimpleName();
	static final String LOG_TAG = "godot::" + CLASS_NAME;


	static final String TEMPLATE_READY_SIGNAL = "template_ready";
	// TODO: Define all signals

	public FirebasePlugin(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return CLASS_NAME;
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		signals.add(new SignalInfo(TEMPLATE_READY_SIGNAL, Dictionary.class));

		// TODO: Register all signals

		return signals;
	}

	@Override
	public View onMainCreate(Activity activity) {
		// TODO: Godot activity is ready

		return super.onMainCreate(activity);
	}

	@Override
	public void onGodotSetupCompleted() {
		super.onGodotSetupCompleted();

		// TODO: Godot is ready
	}

	@UsedByGodot
	public Object[] get_firebase() {
		Log.d(LOG_TAG, "get_firebase() invoked");

		List<Dictionary> resultList = new ArrayList<>();

		// TODO: Plugin method

		return resultList.toArray();
	}

	@Override
	public void onMainDestroy() {
		// TODO: Plugin cleanup
	}
}
