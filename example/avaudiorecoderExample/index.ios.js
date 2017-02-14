/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableHighlight,
  Dimensions,
} from 'react-native';
import Recoder from 'react-native-avaudiorecorder';

let width = Dimensions.get('window').width;
let recoder = new Recoder();
export default class avaudiorecoderExample extends Component {
  static path;
  static peak;
  constructor(p){
    super(p);
    this.state = {
      peakInfo:recoder.peakInfo,
    }
  }
  
  componentWillMount() {
    this.listener = recoder.audioUpdaterListener.addListener('onUpdateRecordPeak',this.listenerFun.bind(this,e));
  }
  listenerFun(e){
    console.log(e);
    this.peak = recoder.peakInfo;
  }
  render() {
   return (
      <View style={styles.container}>
        {/*<WKWebView 
                    source = {{uri:"https://www.baidu.com"}}
                    onProgress = {(e)=>console.log(e)}/>*/}
        <View style = {styles.btnViewStyle}>
          <TouchableHighlight onPress = {this._recoder.bind(this)}>
            <View style = {styles.btnStyle}>
              <Text style={{textAlign:'center',color:'#ffffff',fontSize:16}}>开始录音</Text>
            </View>
          </TouchableHighlight>
        </View>
        <View style = {styles.btnViewStyle}>
          <TouchableHighlight onPress = {this._stopRecoder.bind(this)}>
              <View style = {styles.btnStyle}>
                <Text style={{textAlign:'center',color:'#ffffff',fontSize:16}}>停止录音</Text>
              </View>
          </TouchableHighlight>
        </View>
        <View style = {styles.btnViewStyle}>
          <TouchableHighlight onPress = {this._play.bind(this,this.path)}>
              <View style = {styles.btnStyle}>
                <Text style={{textAlign:'center',color:'#ffffff',fontSize:16}}>播放录音</Text>
              </View>
          </TouchableHighlight>
        </View>
        <View style = {styles.btnViewStyle}>
          <View style = {styles.btnStyle}>
            <Text>{recoder.peakInfo.recordPeak}</Text>
          </View>
        </View>
      </View>
    );
  }

  _recoder(){
    recoder.parpreRecoder().then(
      e=>{
        console.log(e);
        recoder.startRecorder((err,msg)=>{
          console.log(err);
          console.log(msg);
        });
      }
    ).catch(e=>{
      console.log(e);
    });
  }

  _stopRecoder(){
    recoder.stopRecorder((err,msg)=>{
      if(err){
        console.log(err);
      }else{
        console.log(msg);
        this.path = msg.path;
      }
    });
  }
  
  _play(path){

    recoder.play(this.path,(succ)=>{
      console.log(this.path);
      recoder.deleteCurrentRecord((err,msg)=>{
        console.log(msg);
      });
    })
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
  btnViewStyle:{
    width:width*0.8,
    height:50,
    marginVertical:5,
  },
  btnStyle:{
    width:width*0.8,
    height:40,
    backgroundColor:'rgb(63,173,15)',
    justifyContent:'center',
    alignItems:'center',
    borderRadius:3,
  }
});

AppRegistry.registerComponent('avaudiorecoderExample', () => avaudiorecoderExample);
