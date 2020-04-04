/*
Copyright (C) 2020 SIRSLab - University of Siena  <Gianluca, Nicole, Tommaso>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

package it.unisi.sirslab.covidwear

import android.content.Intent
import android.os.Bundle
import android.support.wearable.activity.WearableActivity
import android.view.View
import android.view.Window
import kotlin.system.exitProcess

class MainActivity : WearableActivity(),  View.OnClickListener {

    private var screen_number  = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main1)
    }

    override fun onClick(v: View?) {
        if(screen_number == 0){
            setContentView(R.layout.activity_main2)
            screen_number += 1
        }
        else if(screen_number == 1 && v!!.id==R.id.enterButton){
            setContentView(R.layout.activity_main3)
            screen_number += 1
        }
        else if(screen_number == 2 && v!!.id==R.id.acceptButton) {
            val intent = Intent(this, NFTActivity::class.java)
            startActivity(intent)
            finishAffinity()
        }
        else if(screen_number == 2 && v!!.id==R.id.denyButton) {
            finish()
            finishAffinity()
            exitProcess(status = 0)
        }
    }
}