<div id="<?php echo $popup_id ?>" class="snapshot-three wps-popup-modal">

	<div class="wps-popup-mask"></div>

	<div class="wps-popup-content">

		<div class="wpmud-box">

			<div class="wpmud-box-title can-close">

				<h3><?php echo $popup_title; ?></h3>

				<i class="wps-icon i-close wps-popup-close"></i>

			</div>

			<div class="wpmud-box-content">

				<div class="row">

					<div class="col-xs-12 col-sm-12 col-md-12 col-lg-12">

						<p><?php echo $popup_content; ?></p>

						<div class="wps-confirmation-buttons">

							<a href="<?php echo $popup_cancel_url; ?>" class="wps-popup-close button button-outline button-gray"><?php echo $popup_cancel_title; ?></a>

							<a href="<?php echo $popup_action_url; ?>" class="button button-blue"><?php echo $popup_action_title; ?></a>

						</div>

					</div>

				</div>

			</div>

		</div>

	</div>

</div>